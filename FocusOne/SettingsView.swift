import SwiftUI
import ApplicationServices

struct SettingsView: View {
    @Bindable var monitor: WindowMonitor
    @State private var launchAtLogin: Bool = false
    @State private var opacityVal: Double = 0.6
    
    var body: some View {
        VStack(spacing: 20) {
            Toggle("开启专注模式", isOn: Binding(
                get: { monitor.isEnabled },
                set: { newValue in
                    if newValue {
                        // 检查权限
                        if checkAccessibilityPermission() {
                            monitor.setRunningState(true)
                        } else {
                            // 如果没权限，禁止开启功能
                            monitor.setRunningState(false)
                        }
                    } else {
                        // 关闭不需要权限
                        monitor.setRunningState(false)
                    }
                }
            ))
            .toggleStyle(.switch)
            .font(.headline)
            
            Divider()
            
            Picker("模式", selection: $monitor.currentMode) {
                Text("单窗口").tag(WindowMonitor.AppMode.single)
                Text("当前应用").tag(WindowMonitor.AppMode.app)
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(!monitor.isEnabled)
            
            HStack {
                Text("亮度")
                Slider(value: $opacityVal, in: 0.1...0.9) { _ in
                    monitor.updateOpacity(opacityVal)
                }
            }
            .disabled(!monitor.isEnabled)
            
            Divider()
            
            Toggle("开机自动启动", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    LaunchManager.shared.toggleLaunchAtLogin(enabled: newValue)
                }
            
            Button("退出应用") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            self.opacityVal = monitor.savedOpacity
            if monitor.isEnabled {
                monitor.updateOpacity(monitor.savedOpacity)
            }
            
            self.launchAtLogin = LaunchManager.shared.isLaunchAtLoginEnabled
        }
    }

    private func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
