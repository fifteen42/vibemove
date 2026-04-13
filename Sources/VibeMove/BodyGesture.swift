import CoreGraphics
import Foundation

enum BodyGesture: String {
    case none
    case clap
    case crossArms
    // squat is detected temporally in BodyController.
}

enum BodyGestureClassifier {
    static func classify(_ lm: BodyLandmarks) -> BodyGesture {
        let shoulderWidth = dist(lm.leftShoulder, lm.rightShoulder)
        guard shoulderWidth > 0.05 else { return .none }

        if isClap(lm, shoulderWidth: shoulderWidth) { return .clap }
        if isCrossArms(lm) { return .crossArms }
        return .none
    }

    private static func isClap(_ lm: BodyLandmarks, shoulderWidth: CGFloat) -> Bool {
        // Wrists close together and above hips (at chest/face height).
        // Also require both wrists to be detected (y > 0.01 excludes zero-fallback).
        guard lm.leftWrist.y > 0.01, lm.rightWrist.y > 0.01 else { return false }
        let wristGap = dist(lm.leftWrist, lm.rightWrist)
        guard wristGap < shoulderWidth * 0.5 else { return false }
        let hipY = (lm.leftHip.y + lm.rightHip.y) / 2
        guard lm.leftWrist.y > hipY, lm.rightWrist.y > hipY else { return false }
        return true
    }

    private static func isCrossArms(_ lm: BodyLandmarks) -> Bool {
        // Each wrist must end up on the OPPOSITE side from its own shoulder.
        // This is invariant to camera mirroring.
        let midX = (lm.leftShoulder.x + lm.rightShoulder.x) / 2
        let leftCrossed = (lm.leftWrist.x - midX) * (lm.leftShoulder.x - midX) < 0
        let rightCrossed = (lm.rightWrist.x - midX) * (lm.rightShoulder.x - midX) < 0
        guard leftCrossed, rightCrossed else { return false }

        // Both wrists at chest level (between hip and shoulder).
        let hipY = (lm.leftHip.y + lm.rightHip.y) / 2
        let shoulderY = (lm.leftShoulder.y + lm.rightShoulder.y) / 2
        guard lm.leftWrist.y > hipY, lm.leftWrist.y < shoulderY else { return false }
        guard lm.rightWrist.y > hipY, lm.rightWrist.y < shoulderY else { return false }
        return true
    }

    private static func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
}
