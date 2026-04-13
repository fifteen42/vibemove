import AVFoundation
import CoreGraphics
import Foundation

setbuf(stdout, nil)

// Stability / debounce.
let neededFrames = 3
let rearmFrames = 5
let pinchNeededFrames = 2
let pinchCooldownSeconds: TimeInterval = 0.8

// Swipe-down config.
let swipeWindowSeconds: TimeInterval = 0.4
let swipeMinDropRatio: CGFloat = 0.25
let swipeCooldownSeconds: TimeInterval = 1.0

// Squat config.
let squatWindowSeconds: TimeInterval = 2.0
let squatMinDipRatio: CGFloat = 0.30   // as fraction of torso length
let squatRiseBackRatio: CGFloat = 0.10
let squatCooldownSeconds: TimeInterval = 1.5
let squatMinFrames = 10

final class EdgeTrigger {
    private var streak = 0
    private var awayStreak = 999
    private var armed = true
    let needed: Int
    let rearm: Int
    init(needed: Int = neededFrames, rearm: Int = rearmFrames) {
        self.needed = needed
        self.rearm = rearm
    }

    func update(_ active: Bool) -> Bool {
        if active {
            awayStreak = 0
            streak += 1
            if armed && streak >= needed {
                armed = false
                return true
            }
        } else {
            streak = 0
            awayStreak += 1
            if awayStreak >= rearm {
                armed = true
            }
        }
        return false
    }
}

// MARK: - Hand mode controller

final class HandController {
    private let thumbsUp = EdgeTrigger()
    private let pointIndex = EdgeTrigger()
    private let peace = EdgeTrigger()
    private let rock = EdgeTrigger()

    private var pinchStreak = 0
    private var lastPinchAt: Date = .distantPast

    private var wristHistory: [(Date, CGFloat)] = []
    private var lastSwipeAt: Date = .distantPast

    func handle(_ gesture: Gesture, wristY: CGFloat?) {
        if let y = wristY {
            let now = Date()
            wristHistory.append((now, y))
            wristHistory = wristHistory.filter { now.timeIntervalSince($0.0) <= swipeWindowSeconds }
        } else {
            wristHistory.removeAll()
        }

        if thumbsUp.update(gesture == .thumbsUp) {
            Keyboard.tapFn()
            Feedback.play("Tink")
            print("[thumbsUp] Fn tap (toggle)")
        }
        if pointIndex.update(gesture == .pointIndex) {
            Keyboard.tapCmdA()
            Feedback.play("Morse")
            print("[pointIndex] Cmd+A")
        }
        if peace.update(gesture == .peace) {
            Keyboard.tapCmdV()
            Feedback.play("Glass")
            print("[peace] Cmd+V")
        }
        if rock.update(gesture == .rock) {
            Keyboard.tapCmdC()
            Feedback.play("Hero")
            print("[rock] Cmd+C")
        }

        if gesture == .pinch {
            pinchStreak += 1
            if pinchStreak >= pinchNeededFrames,
               Date().timeIntervalSince(lastPinchAt) > pinchCooldownSeconds {
                lastPinchAt = Date()
                pinchStreak = 0
                Keyboard.tapReturn()
                Feedback.play("Pop")
                print("[pinch] Enter")
            }
        } else {
            pinchStreak = 0
        }

        if gesture == .openPalm {
            detectSwipeDown()
        }
    }

    private func detectSwipeDown() {
        guard wristHistory.count >= 4 else { return }
        guard Date().timeIntervalSince(lastSwipeAt) > swipeCooldownSeconds else { return }
        let maxY = wristHistory.map { $0.1 }.max() ?? 0
        let minY = wristHistory.map { $0.1 }.min() ?? 0
        let drop = maxY - minY
        guard drop >= swipeMinDropRatio else { return }
        guard let latest = wristHistory.last?.1, latest <= minY + 0.02 else { return }
        lastSwipeAt = Date()
        wristHistory.removeAll()
        Keyboard.tapEscape()
        Feedback.play("Funk")
        print("[swipeDown] Escape")
    }
}

// MARK: - Body mode controller

final class BodyController {
    private let clap = EdgeTrigger(needed: 1, rearm: 8)
    private let crossArms = EdgeTrigger(needed: 2, rearm: 8)
    private var hipHistory: [(Date, CGFloat, CGFloat)] = []  // (time, hipY, torsoLen)
    private var lastSquatAt: Date = .distantPast
    private var frameCount = 0
    private var noBodyStreak = 0

    func handle(_ lm: BodyLandmarks?) {
        frameCount += 1
        guard let lm = lm else {
            hipHistory.removeAll()
            _ = clap.update(false)
            _ = crossArms.update(false)
            noBodyStreak += 1
            if frameCount % 30 == 0 {
                print("[debug] no body in frame (\(noBodyStreak) frames)")
            }
            return
        }
        noBodyStreak = 0

        let gesture = BodyGestureClassifier.classify(lm)
        if frameCount % 30 == 0 {
            let hipY = (lm.leftHip.y + lm.rightHip.y) / 2
            let shoY = (lm.leftShoulder.y + lm.rightShoulder.y) / 2
            let torso = shoY - hipY
            let maxH = hipHistory.map { $0.1 }.max() ?? 0
            let minH = hipHistory.map { $0.1 }.min() ?? 0
            let dip = maxH - minH
            let dipRatio = torso > 0 ? dip / torso : 0
            print(String(format: "[debug] body OK  hipY=%.3f torso=%.3f history=%d dip=%.3f (%.0f%% of torso) gesture=%@",
                         Double(hipY), Double(torso), hipHistory.count, Double(dip), Double(dipRatio * 100), gesture.rawValue))
        }

        if clap.update(gesture == .clap) {
            Keyboard.tapReturn()
            Feedback.play("Pop")
            print("[clap] Enter")
        }
        if crossArms.update(gesture == .crossArms) {
            Keyboard.tapEscape()
            Feedback.play("Funk")
            print("[crossArms] Escape")
        }

        detectSquat(lm)
    }

    private func detectSquat(_ lm: BodyLandmarks) {
        let hipY = (lm.leftHip.y + lm.rightHip.y) / 2
        let shoulderY = (lm.leftShoulder.y + lm.rightShoulder.y) / 2
        let torso = shoulderY - hipY
        guard torso > 0.05 else { return }
        let now = Date()
        hipHistory.append((now, hipY, torso))
        hipHistory = hipHistory.filter { now.timeIntervalSince($0.0) <= squatWindowSeconds }
        guard hipHistory.count >= squatMinFrames else { return }
        guard now.timeIntervalSince(lastSquatAt) > squatCooldownSeconds else { return }

        let maxY = hipHistory.map { $0.1 }.max() ?? 0
        let minY = hipHistory.map { $0.1 }.min() ?? 0
        let dip = maxY - minY
        guard dip > torso * squatMinDipRatio else { return }
        guard hipY > maxY - torso * squatRiseBackRatio else { return }

        lastSquatAt = now
        hipHistory.removeAll()
        Keyboard.tapFn()
        Feedback.play("Tink")
        print("[squat] Fn tap (toggle)")
    }
}

// MARK: - Setup

func requestCameraAccess() -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
        return true
    case .notDetermined:
        let sema = DispatchSemaphore(value: 0)
        var granted = false
        AVCaptureDevice.requestAccess(for: .video) { ok in
            granted = ok
            sema.signal()
        }
        sema.wait()
        return granted
    default:
        return false
    }
}

// Parse --mode argument.
var mode = "hand"
let args = CommandLine.arguments
if let i = args.firstIndex(of: "--mode"), i + 1 < args.count {
    mode = args[i + 1]
}
guard mode == "hand" || mode == "body" else {
    print("Unknown mode: \(mode). Use --mode hand or --mode body.")
    exit(1)
}

print("VibeMove — mode: \(mode)")
if mode == "hand" {
    print("  👍 Thumbs up (tap, toggle)      → Fn tap (Typeless dictation)")
    print("  👌 Thumb + index pinch          → Enter")
    print("  🖐️  Open palm swipe down         → Escape")
    print("  ☝️  Index only                  → Cmd+A (select all)")
    print("  ✌️  Peace sign                   → Cmd+V (paste)")
    print("  🤘 Rock sign                    → Cmd+C (copy)")
} else {
    print("  🏋️ Squat (dip and rise)         → Fn tap (Typeless dictation)")
    print("  👏 Clap (wrists meet at chest)  → Enter")
    print("  ❌ Arms cross X at chest        → Escape")
    print("  (camera must see head → hips, ideally to knees)")
}
print("  Ctrl+C to quit")
print("")

guard requestCameraAccess() else {
    print("Camera access denied. Grant it in System Settings → Privacy & Security → Camera.")
    exit(1)
}

// Keep strong references at module scope so detector + controller + delegate
// stay alive for the lifetime of RunLoop.main.
var handController: HandController?
var handDetector: HandDetector?
var bodyController: BodyController?
var bodyDetector: BodyDetector?

if mode == "hand" {
    let c = HandController()
    let d = HandDetector()
    d.onLandmarks = { lm in
        guard let lm = lm else {
            c.handle(.none, wristY: nil)
            return
        }
        let g = GestureClassifier.classify(lm)
        c.handle(g, wristY: lm.wrist.y)
    }
    do {
        try d.start()
        print("Camera started. Show your hand.")
    } catch {
        print("Failed to start camera: \(error.localizedDescription)")
        exit(1)
    }
    handController = c
    handDetector = d
} else {
    let c = BodyController()
    let d = BodyDetector()
    d.onLandmarks = { lm in
        c.handle(lm)
    }
    do {
        try d.start()
        print("Camera started. Stand in frame.")
    } catch {
        print("Failed to start camera: \(error.localizedDescription)")
        exit(1)
    }
    bodyController = c
    bodyDetector = d
}

signal(SIGINT) { _ in
    print("\nBye.")
    exit(0)
}

RunLoop.main.run()
