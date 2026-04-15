# VibeMove

[English](README.md) | **简体中文**

macOS 上的 vibe coding 助手。摄像头就是控制器。

竖拇指开听写，捏合发送，深蹲开麦。不需要外设，不需要连线——只有 Apple Vision 和你自己。

## 两种模式

- **`body`** *（默认）* —— 深蹲、击掌、双臂交叉。适合站立办公桌，或者任何你不想继续坐着的时候。
- **`hand`** —— 不方便做大动作时用的手指手势。

```bash
swift run VibeMove                       # body 模式
swift run VibeMove -- --mode hand        # hand 模式
```

## Hand 模式

| 手势 | 对应按键 |
| --- | --- |
| 👍 竖拇指 | Fn（听写开关） |
| 👌 捏合 | Enter |
| 🖐️ 张开手掌下挥 | Escape |
| ☝️ 只伸食指 | ⌘A |
| ✌️ Peace | ⌘V |
| 🤘 Rock | ⌘C |

## Body 模式

摄像头要能看到你从头到髋。笔电平放在桌上看不到——请垫高或离远一点。

| 动作 | 对应按键 |
| --- | --- |
| 🏋️ 深蹲 | Fn（听写开关） |
| 👏 击掌 | Enter |
| ❌ 双臂胸前 X 交叉 | Escape |

每次成功触发都会播放不同的 macOS 系统音，不用看屏幕就知道是哪个。

## 安装

到 [Releases](https://github.com/fifteen42/vibemove/releases) 下载最新 zip，解压后把 `VibeMove.app` 拖进 `Applications`。

首次启动：构建未签名，右键点 `VibeMove.app` → **打开**，绕过 Gatekeeper。或者：

```bash
xattr -cr /Applications/VibeMove.app
```

### 从源码构建

```bash
git clone https://github.com/fifteen42/vibemove.git
cd vibemove
swift build
swift run VibeMove
```

### 自己打包 `.app`

```bash
bash scripts/package.sh 0.1.0
```

## 权限

1. **摄像头** —— 首次启动自动弹窗。
2. **辅助功能** —— 系统设置 → 隐私与安全性 → 辅助功能 → 把你的终端 app 加进去。

## 运行要求

macOS 13+，带摄像头的 Mac，Swift 5.9+。

## 调参

`Sources/VibeMove/main.swift` 顶部的常量：

| 常量 | 默认值 | 作用 |
| --- | --- | --- |
| `neededFrames` | 3 | 手势稳定多少帧才触发 |
| `rearmFrames` | 5 | 手势离开多少帧才能再次触发 |
| `pinchCooldownSeconds` | 0.8 | 两次 Enter 的最小间隔 |
| `swipeMinDropRatio` | 0.25 | 手腕下挥幅度（画面高度百分比） |
| `squatMinDipRatio` | 0.30 | 深蹲幅度（躯干长度百分比） |
| `squatCooldownSeconds` | 1.5 | 两次深蹲的最小间隔 |

## 工作原理

- `AVCaptureSession`，640×480
- Apple Vision 做手部（21 关键点）和身体（19 关键点）姿态估计，完全离线
- 基于归一化坐标的几何判断，没有 ML 训练
- `CGEvent` 模拟键盘。Fn 键用 `.flagsChanged` 事件而不是 `keyDown`，否则 macOS 会以为 Fn 一直按着开始放大屏幕
- 屏幕右下角有个小的骨架 HUD，显示检测器实时看到的东西

## 致谢

精神层面受到 [wong2/vibe-ring](https://github.com/wong2/vibe-ring) 启发。

## 许可证

MIT
