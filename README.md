# VibeMove

**English** | [简体中文](README.zh-CN.md)

A vibe coding companion for macOS. Your camera is the controller.

Thumbs up to dictate. Pinch to send. Squat to turn on the mic. No hardware, no wires — just Apple Vision and your body.

## Two modes

- **`body`** *(default)* — squat, clap, arms cross. For standing desks or any time you're tired of sitting.
- **`hand`** — subtle finger gestures when body motion isn't an option.

```bash
swift run VibeMove                       # body mode
swift run VibeMove -- --mode hand        # hand mode
```

## Hand mode

| Gesture | Action |
| --- | --- |
| 👍 Thumbs up | Fn (dictation toggle) |
| 👌 Pinch | Enter |
| 🖐️ Palm swipe down | Escape |
| ☝️ Index up | ⌘A |
| ✌️ Peace | ⌘V |
| 🤘 Rock | ⌘C |

## Body mode

Camera must see head to hips. Laptop flat on a desk won't work — prop it up or step back.

| Motion | Action |
| --- | --- |
| 🏋️ Squat | Fn (dictation toggle) |
| 👏 Clap | Enter |
| ❌ Arms cross X | Escape |

Every trigger plays a distinct macOS system sound so you know what fired.

## Install

Download the latest zip from [Releases](https://github.com/fifteen42/vibemove/releases), unzip, and drag `VibeMove.app` into `Applications`.

First launch: the build is unsigned, so right-click → Open to bypass Gatekeeper. Or:

```bash
xattr -cr /Applications/VibeMove.app
```

### Build from source

```bash
git clone https://github.com/fifteen42/vibemove.git
cd vibemove
swift build
swift run VibeMove
```

### Package your own `.app`

```bash
bash scripts/package.sh 0.1.0
```

## Permissions

1. **Camera** — auto-prompted on first launch.
2. **Accessibility** — System Settings → Privacy & Security → Accessibility → add your terminal app.

## Requirements

macOS 13+, a Mac with a camera, Swift 5.9+.

## Tuning

Thresholds live at the top of `Sources/VibeMove/main.swift`:

| Knob | Default | Controls |
| --- | --- | --- |
| `neededFrames` | 3 | Frames of stability before a hand gesture fires |
| `rearmFrames` | 5 | Frames of absence before it can fire again |
| `pinchCooldownSeconds` | 0.8 | Min gap between Enter taps |
| `swipeMinDropRatio` | 0.25 | Wrist drop as fraction of frame height |
| `squatMinDipRatio` | 0.30 | Hip drop as fraction of torso length |
| `squatCooldownSeconds` | 1.5 | Min gap between squats |

## How it works

- `AVCaptureSession` at 640×480
- Apple Vision for hand (21 joints) and body (19 joints) pose, fully offline
- Plain geometry on normalized coordinates — no ML training
- `CGEvent` for keyboard injection. Fn uses `.flagsChanged`, not `keyDown`, otherwise macOS thinks Fn is stuck and starts zooming the screen
- Small skeleton HUD in the bottom-right corner showing what the detector sees

## Credit

Inspired in spirit by [wong2/vibe-ring](https://github.com/wong2/vibe-ring).

## License

MIT
