# VibeMove

**English** | [简体中文](README.zh-CN.md)

> Move to type. A camera-driven companion to [vibe-ring](https://github.com/wong2/vibe-ring) — but instead of a Joy-Con, your own body is the controller.

VibeMove turns **hand gestures** and **body motions** into macOS keyboard shortcuts. Flash a thumbs up to start dictation. Pinch to hit Enter. Or stand up and do a **squat** to toggle dictation — and get a workout while you vibe-code.

The whole point: make your AI workflow *physical*. Every prompt is a rep.

## Modes

VibeMove runs in one of two modes, picked at launch:

| Mode | Vibe | Who it's for |
| --- | --- | --- |
| **`body`** (default) | Loud. Stand up, move. | Standing desk, kitchen, living room — away from the keyboard. The whole point. |
| **`hand`** | Subtle. Sit at your desk. | Coding, writing, editing — close to the keyboard. |

```bash
swift run VibeMove                       # body mode (default)
swift run VibeMove -- --mode hand        # hand mode
```

## Hand Mode

Six hand gestures → six keyboard actions. Detected by Apple's Vision framework (`VNDetectHumanHandPoseRequest`), runs **fully offline**.

| Gesture | Action | Notes |
| --- | --- | --- |
| 👍 Thumbs up (tap) | **Fn** (Typeless dictation toggle) | Nothing to hold — tap once to start dictating, tap again to stop. Matches Typeless's toggle semantics. |
| 👌 Thumb + index pinch | **Enter** | Send the transcribed message. |
| 🖐️ Open palm, swipe down | **Escape** | Cancel / dismiss. |
| ☝️ Index finger only | **⌘A** | Select all. |
| ✌️ Peace sign | **⌘V** | Paste. V shape = V key. |
| 🤘 Rock sign | **⌘C** | Copy. |

## Body Mode

Three full-body actions → three keyboard actions. Uses `VNDetectHumanBodyPoseRequest`. **Camera must see at least your head through your hips** — laptop cameras on a desk won't cut it. Mount it higher or step back.

| Motion | Action | Notes |
| --- | --- | --- |
| 🏋️ **Squat** (dip and rise) | **Fn** (Typeless dictation toggle) | Fires on the rise back up, after at least a 30%-of-torso hip drop. |
| 👏 **Clap** (wrists meet at chest) | **Enter** | Send. |
| ❌ **Arms cross X** (at chest level) | **Escape** | Cancel. |

The body-mode philosophy: if you're going to talk to an AI, **earn the prompt**.

## Feedback

Every successful trigger plays a distinct macOS system sound so you always know what just fired:

| Action | Sound |
| --- | --- |
| Fn (dictation) | Tink |
| Enter | Pop |
| Escape | Funk |
| ⌘A | Morse |
| ⌘V | Glass |
| ⌘C | Hero |

## Requirements

- macOS 13+
- Apple Silicon or Intel Mac with a camera
- Swift 5.9+
- Accessibility permission (for simulating keystrokes)
- Camera permission (prompted on first run)

## Setup

```bash
git clone https://github.com/fifteen42/vibemove.git
cd vibemove
swift build
swift run VibeMove                       # body mode (default)
swift run VibeMove -- --mode hand        # hand mode
```

### Permissions

On first run:

1. **Camera**: accept the prompt.
2. **Accessibility**: System Settings → Privacy & Security → Accessibility → add your terminal app (Terminal, iTerm2, Ghostty, …). Required for VibeMove to post keyboard events.

## Tuning

Thresholds live at the top of `Sources/VibeMove/main.swift`. If gestures are too sensitive or too hard to trigger, tweak:

| Constant | Default | Controls |
| --- | --- | --- |
| `neededFrames` | 3 | Stable frames required for hand gestures to fire. |
| `rearmFrames` | 5 | Frames the gesture must leave the pose before it can fire again. |
| `pinchCooldownSeconds` | 0.8 | Minimum interval between two Enter taps. |
| `swipeMinDropRatio` | 0.25 | Wrist drop (as fraction of frame height) to count as a down swipe. |
| `squatMinDipRatio` | 0.30 | Hip drop (as fraction of torso length) for a valid squat. |
| `squatCooldownSeconds` | 1.5 | Minimum interval between two squats. |

## How it works

- **Camera** → `AVCaptureSession` at 640×480.
- **Vision** → `VNDetectHumanHandPoseRequest` (21 hand keypoints) or `VNDetectHumanBodyPoseRequest` (19 body keypoints).
- **Classifier** → plain geometry over normalized keypoint coordinates. No ML training.
- **Keyboard** → `CGEvent`. `Fn` is special: simulated via `.flagsChanged` events (not keyDown), so the OS doesn't think Fn is stuck down and start zooming your screen.
- **Feedback** → `NSSound` on built-in system sounds.
- **Lifecycle** → detector + controller live at module scope so ARC doesn't release the AV delegate mid-session.

## Credit

Inspired by [wong2/vibe-ring](https://github.com/wong2/vibe-ring), which does the same thing with a Nintendo Ring-Con. VibeMove is the camera-native cousin — same vibe, no hardware.

## License

MIT
