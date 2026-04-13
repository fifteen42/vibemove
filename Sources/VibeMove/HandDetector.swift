import AVFoundation
import CoreImage
import Foundation
import Vision

struct HandLandmarks {
    let wrist: CGPoint
    let thumbCMC: CGPoint
    let thumbMP: CGPoint
    let thumbIP: CGPoint
    let thumbTip: CGPoint
    let indexMCP: CGPoint
    let indexPIP: CGPoint
    let indexDIP: CGPoint
    let indexTip: CGPoint
    let middleMCP: CGPoint
    let middleTip: CGPoint
    let ringMCP: CGPoint
    let ringTip: CGPoint
    let littleMCP: CGPoint
    let littleTip: CGPoint
}

final class HandDetector: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "vibe-hand.camera")
    private let request: VNDetectHumanHandPoseRequest

    var onLandmarks: ((HandLandmarks?) -> Void)?

    override init() {
        request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        super.init()
    }

    func start() throws {
        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        guard let device = AVCaptureDevice.default(for: .video) else {
            throw NSError(domain: "VibeHand", code: 1, userInfo: [NSLocalizedDescriptionKey: "No camera"])
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw NSError(domain: "VibeHand", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot add camera input"])
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else {
            throw NSError(domain: "VibeHand", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot add output"])
        }
        session.addOutput(output)

        session.commitConfiguration()
        session.startRunning()
    }

    func stop() {
        session.stopRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else {
                onLandmarks?(nil)
                return
            }
            let points = try observation.recognizedPoints(.all)
            func pt(_ joint: VNHumanHandPoseObservation.JointName) -> CGPoint {
                guard let p = points[joint], p.confidence > 0.3 else { return .zero }
                return CGPoint(x: p.location.x, y: p.location.y)
            }
            let lm = HandLandmarks(
                wrist: pt(.wrist),
                thumbCMC: pt(.thumbCMC),
                thumbMP: pt(.thumbMP),
                thumbIP: pt(.thumbIP),
                thumbTip: pt(.thumbTip),
                indexMCP: pt(.indexMCP),
                indexPIP: pt(.indexPIP),
                indexDIP: pt(.indexDIP),
                indexTip: pt(.indexTip),
                middleMCP: pt(.middleMCP),
                middleTip: pt(.middleTip),
                ringMCP: pt(.ringMCP),
                ringTip: pt(.ringTip),
                littleMCP: pt(.littleMCP),
                littleTip: pt(.littleTip)
            )
            onLandmarks?(lm)
        } catch {
            onLandmarks?(nil)
        }
    }
}
