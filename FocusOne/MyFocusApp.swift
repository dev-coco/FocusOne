import SwiftUI

@main
struct MyFocusApp: App {
    // 初始化 WindowMonitor，调用 init()
    // 触发 startMonitoring() 遮罩层立即生效
    @State private var monitor = WindowMonitor()
    
    var body: some Scene {
        MenuBarExtra("FocusOneMenu", image: "MenuIcon") {
            SettingsView(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}
