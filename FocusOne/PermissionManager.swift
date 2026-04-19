import SwiftUI
import ApplicationServices

struct PermissionManager {
    
    // 检查是否拥有辅助功能权限
    static func checkAccessibilityPermission() -> Bool {
        // kAXTrustedCheckOptionPrompt: true 表示如果没权限，系统会尝试弹出一个默认的提示框
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    // 打开辅助功能界面
    static func openAccessibilitySettings() {
        // 这个 URL 可以直接跳到 macOS 的辅助功能设置页面
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
