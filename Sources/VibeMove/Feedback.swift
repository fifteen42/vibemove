import AppKit
import Foundation

enum Feedback {
    // macOS built-in system sounds (in /System/Library/Sounds/).
    static func play(_ name: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            NSSound(named: NSSound.Name(name))?.play()
        }
    }
}
