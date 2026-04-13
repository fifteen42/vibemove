import CoreGraphics
import Foundation

enum Gesture: String {
    case none
    case thumbsUp
    case pinch
    case openPalm
    case pointIndex   // ☝️ index only
    case peace        // ✌️ index + middle
    case rock         // 🤘 index + little
}

enum GestureClassifier {
    static func classify(_ lm: HandLandmarks) -> Gesture {
        let handSize = dist(lm.wrist, lm.middleMCP)
        guard handSize > 0.05 else { return .none }

        // Order matters: check most specific first.
        if isThumbsUp(lm, handSize: handSize) { return .thumbsUp }
        if isPinch(lm, handSize: handSize) { return .pinch }
        if isPeace(lm, handSize: handSize) { return .peace }
        if isRock(lm, handSize: handSize) { return .rock }
        if isPointIndex(lm, handSize: handSize) { return .pointIndex }
        if isOpenPalm(lm, handSize: handSize) { return .openPalm }
        return .none
    }

    // Helpers: is a given finger extended / curled?
    private static func extended(_ tip: CGPoint, _ mcp: CGPoint, _ wrist: CGPoint) -> Bool {
        return dist(tip, wrist) > dist(mcp, wrist) * 1.5
    }

    private static func curled(_ tip: CGPoint, _ mcp: CGPoint, _ wrist: CGPoint) -> Bool {
        return dist(tip, wrist) < dist(mcp, wrist) * 1.25
    }

    private static func isPointIndex(_ lm: HandLandmarks, handSize: CGFloat) -> Bool {
        // Index extended, middle/ring/little curled.
        guard extended(lm.indexTip, lm.indexMCP, lm.wrist) else { return false }
        guard curled(lm.middleTip, lm.middleMCP, lm.wrist) else { return false }
        guard curled(lm.ringTip, lm.ringMCP, lm.wrist) else { return false }
        guard curled(lm.littleTip, lm.littleMCP, lm.wrist) else { return false }
        return true
    }

    private static func isPeace(_ lm: HandLandmarks, handSize: CGFloat) -> Bool {
        // Index + middle extended, ring + little curled.
        guard extended(lm.indexTip, lm.indexMCP, lm.wrist) else { return false }
        guard extended(lm.middleTip, lm.middleMCP, lm.wrist) else { return false }
        guard curled(lm.ringTip, lm.ringMCP, lm.wrist) else { return false }
        guard curled(lm.littleTip, lm.littleMCP, lm.wrist) else { return false }
        // Spread index and middle apart (not touching) — distinguishes from "gun" pose.
        guard dist(lm.indexTip, lm.middleTip) > handSize * 0.3 else { return false }
        return true
    }

    private static func isRock(_ lm: HandLandmarks, handSize: CGFloat) -> Bool {
        // Index + little extended, middle + ring curled.
        guard extended(lm.indexTip, lm.indexMCP, lm.wrist) else { return false }
        guard extended(lm.littleTip, lm.littleMCP, lm.wrist) else { return false }
        guard curled(lm.middleTip, lm.middleMCP, lm.wrist) else { return false }
        guard curled(lm.ringTip, lm.ringMCP, lm.wrist) else { return false }
        return true
    }

    private static func isOpenPalm(_ lm: HandLandmarks, handSize: CGFloat) -> Bool {
        // All four non-thumb fingers clearly extended.
        let fingers: [(CGPoint, CGPoint)] = [
            (lm.indexTip, lm.indexMCP),
            (lm.middleTip, lm.middleMCP),
            (lm.ringTip, lm.ringMCP),
            (lm.littleTip, lm.littleMCP),
        ]
        for (tip, mcp) in fingers {
            let tipDist = dist(tip, lm.wrist)
            let mcpDist = dist(mcp, lm.wrist)
            if tipDist < mcpDist * 1.5 { return false }
        }
        // Thumb also spread (away from index MCP).
        if dist(lm.thumbTip, lm.indexMCP) < handSize * 0.6 { return false }
        return true
    }

    private static func isThumbsUp(_ lm: HandLandmarks, handSize: CGFloat) -> Bool {
        // Vision's normalized coords: origin bottom-left, y grows upward.
        // Thumb must point clearly up: tip above IP above MP above CMC.
        guard lm.thumbTip.y > lm.thumbIP.y,
              lm.thumbIP.y > lm.thumbMP.y,
              lm.thumbTip.y > lm.indexMCP.y + 0.15 * handSize
        else { return false }

        // Thumb extended: tip far from wrist relative to MP.
        let thumbExtension = dist(lm.thumbTip, lm.wrist) / max(dist(lm.thumbMP, lm.wrist), 0.001)
        guard thumbExtension > 1.25 else { return false }

        // Other four fingers curled: tip distance to wrist ≈ MCP distance (not extended).
        let curled: [(CGPoint, CGPoint)] = [
            (lm.indexTip, lm.indexMCP),
            (lm.middleTip, lm.middleMCP),
            (lm.ringTip, lm.ringMCP),
            (lm.littleTip, lm.littleMCP),
        ]
        for (tip, mcp) in curled {
            let tipDist = dist(tip, lm.wrist)
            let mcpDist = dist(mcp, lm.wrist)
            if tipDist > mcpDist * 1.25 { return false }
        }
        return true
    }

    private static func isPinch(_ lm: HandLandmarks, handSize: CGFloat) -> Bool {
        // Thumb tip touches index tip.
        let gap = dist(lm.thumbTip, lm.indexTip)
        guard gap < 0.22 * handSize else { return false }

        // Middle/ring/little should be extended (distinguishes OK sign from full fist).
        let extended: [(CGPoint, CGPoint)] = [
            (lm.middleTip, lm.middleMCP),
            (lm.ringTip, lm.ringMCP),
        ]
        for (tip, mcp) in extended {
            let tipDist = dist(tip, lm.wrist)
            let mcpDist = dist(mcp, lm.wrist)
            if tipDist < mcpDist * 1.25 { return false }
        }
        return true
    }

    private static func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
}
