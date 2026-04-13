import AVFoundation
import CoreImage
import Foundation
import Vision

struct BodyLandmarks {
    let nose: CGPoint
    let leftShoulder: CGPoint
    let rightShoulder: CGPoint
    let leftHip: CGPoint
    let rightHip: CGPoint
    let leftWrist: CGPoint
    let rightWrist: CGPoint
    let leftKnee: CGPoint
    let rightKnee: CGPoint
}

final class BodyDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "vibehand.body")
    private let request: VNDetectHumanBodyPoseRequest

    var onLandmarks: ((BodyLandmarks?) -> Void)?

    override init() {
        request = VNDetectHumanBodyPoseRequest()
        super.init()
    }

    func start() throws {
        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        guard let device = AVCaptureDevice.default(for: .video) else {
            throw NSError(domain: "Vibehand", code: 1, userInfo: [NSLocalizedDescriptionKey: "No camera"])
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw NSError(domain: "Vibehand", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot add input"])
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else {
            throw NSError(domain: "Vibehand", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot add output"])
        }
        session.addOutput(output)

        session.commitConfiguration()
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
            guard let obs = request.results?.first else {
                onLandmarks?(nil)
                return
            }
            let points = try obs.recognizedPoints(.all)
            func pt(_ j: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
                guard let p = points[j], p.confidence > 0.3 else { return nil }
                return CGPoint(x: p.location.x, y: p.location.y)
            }
            // Core joints must all be confident — squat and clap both need shoulders + hips.
            guard
                let leftShoulder = pt(.leftShoulder),
                let rightShoulder = pt(.rightShoulder),
                let leftHip = pt(.leftHip),
                let rightHip = pt(.rightHip)
            else {
                onLandmarks?(nil)
                return
            }
            let lm = BodyLandmarks(
                nose: pt(.nose) ?? .zero,
                leftShoulder: leftShoulder,
                rightShoulder: rightShoulder,
                leftHip: leftHip,
                rightHip: rightHip,
                leftWrist: pt(.leftWrist) ?? .zero,
                rightWrist: pt(.rightWrist) ?? .zero,
                leftKnee: pt(.leftKnee) ?? .zero,
                rightKnee: pt(.rightKnee) ?? .zero
            )
            onLandmarks?(lm)
        } catch {
            onLandmarks?(nil)
        }
    }
}
