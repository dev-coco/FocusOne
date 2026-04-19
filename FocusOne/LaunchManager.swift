import Foundation
import ServiceManagement

class LaunchManager {
    static let shared = LaunchManager()
    
    // 获取当前是否已经设置为开机启动
    var isLaunchAtLoginEnabled: Bool {
        return SMAppService.mainApp.status == .enabled
    }
    
    // 切换开机启动状态
    func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                // 注册当前应用为登录项
                try SMAppService.mainApp.register()
            } else {
                // 取消注册
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("修改开机启动设置失败: \(error.localizedDescription)")
        }
    }
}