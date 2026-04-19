import SwiftUI
import ApplicationServices
import Observation

@Observable
class WindowMonitor {
    // 定义用于 UserDefaults 的 key
    private let kEnabled = "Focus_IsEnabled"
    private let kMode = "Focus_Mode"
    private let kOpacity = "Focus_Opacity"
    private var sessionWindowIDs: Set<Int> = []
    
    // 当属性变化时自动写入 UserDefaults
    var isEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: kEnabled)
        }
    }
    
    // 支持 Int 存储的枚举
    enum AppMode: Int {
        case single = 0
        case app = 1
    }
    
    var currentMode: AppMode = .single {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: kMode)
            if isEnabled { checkWindows() }
        }
    }
    
    // 专门存储亮度的变量
    var savedOpacity: Double = 0.6 {
        didSet {
            UserDefaults.standard.set(savedOpacity, forKey: kOpacity)
        }
    }
    
    // 当目标窗口被其他窗口遮挡比例超过该值时，认为被遮挡
    let occlusionThreshold: CGFloat = 0.8
    private var timer: Timer?
    private let overlayWindow = OverlayWindow() // 单例遮罩窗口
    private var activeWindowIDs: Set<Int> = [] // 记录属于前台进程的窗口 id
    private var lastFrontPID: pid_t = 0 // 记录上一次前台进程 id，用于检测进程切换
    
    init() {
        loadSettings()
    }
    
    // 加载之前保存的设置并根据 savedEnabled 决定是否立即启动监控
    private func loadSettings() {
        // 读取模式
        let savedModeRaw = UserDefaults.standard.integer(forKey: kMode)
        self.currentMode = AppMode(rawValue: savedModeRaw) ?? .single
        
        // 读取亮度
        let savedOp = UserDefaults.standard.double(forKey: kOpacity)
        self.savedOpacity = savedOp > 0 ? savedOp : 0.6
        
        // 读取开关状态
        let savedEnabled = UserDefaults.standard.bool(forKey: kEnabled)
        
        print("启动配置读取: 开关=\(savedEnabled), 模式=\(currentMode), 亮度=\(savedOpacity)")
        
        if savedEnabled {
            self.isEnabled = true
            startMonitoring()
        }
    }
    
    // UI 开关绑定的方法
    func setRunningState(_ isOn: Bool) {
        self.isEnabled = isOn // 会触发 didSet，保存到 UserDefaults
        if isOn {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }
    
    private func startMonitoring() {
        if timer != nil { return }
        
        print("执行：开启专注模式")
        
        DispatchQueue.main.async {
            // 每次启动时确保遮罩窗口尺寸正确，防止 App 启动太早导致窗口为 0x0
            self.overlayWindow.fitScreen()
            
            // 把保存的亮度应用到遮罩视图
            (self.overlayWindow.contentView as? OverlayView)?.opacity = CGFloat(self.savedOpacity)
            
            // 显示窗口
            self.overlayWindow.makeKeyAndOrderFront(nil)
        }
        
        // 创建定时器
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            self.checkWindows()
        }
    }
    
    private func stopMonitoring() {
        print("执行：关闭专注模式")
        // 停止定时器
        timer?.invalidate()
        timer = nil
        
        DispatchQueue.main.async {
            // 隐藏遮罩窗口
            self.overlayWindow.orderOut(nil)
        }
        
        // 清理状态
        activeWindowIDs.removeAll()
        lastFrontPID = 0
    }
    
    // 修改亮度时调用：保存并立即更新 overlay
    func updateOpacity(_ value: Double) {
        self.savedOpacity = value
        if isEnabled {
            DispatchQueue.main.async {
                (self.overlayWindow.contentView as? OverlayView)?.opacity = CGFloat(value)
            }
        }
    }
    
    // 获取当前屏幕上窗口列表，找到前台应用窗口并生成需要高亮区域
    private func checkWindows() {
        if !AXIsProcessTrusted() { return }
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        
        // 记录前台进程变化
        if frontApp.processIdentifier != lastFrontPID {
            sessionWindowIDs.removeAll()
            activeWindowIDs.removeAll()
            lastFrontPID = frontApp.processIdentifier
        }
        guard let mainScreen = NSScreen.main else { return }
        let screenHeight = mainScreen.frame.height
        let screenWidth = mainScreen.frame.width
        
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowInfoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: AnyObject]] else { return }
        
        var visibleHoles: [CGRect] = []
        var higherBlockers: [CGRect] = []
        
        var hasFullscreenWindow = false
        let myPID = ProcessInfo.processInfo.processIdentifier
        
        // 是否已经找到了符合条件的主窗口
        var foundTopmostValidWindow = false

        for info in windowInfoList {
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let ownerPID = info[kCGWindowOwnerPID as String] as? Int32,
                  let windowID = info[kCGWindowNumber as String] as? Int
            else { continue }
            
            if ownerPID == myPID { continue }
            
            let x = boundsDict["X"] ?? 0
            let y = boundsDict["Y"] ?? 0
            let w = boundsDict["Width"] ?? 0
            let h = boundsDict["Height"] ?? 0
            let rawRect = CGRect(x: x, y: y, width: w, height: h)
            

            if ownerPID == frontApp.processIdentifier {
                
                // 全屏检测
                if (abs(w - screenWidth) <= 2 && abs(h - screenHeight) <= 2) {
                    hasFullscreenWindow = true
                    break
                }
                
                let isOnScreen = info[kCGWindowIsOnscreen as String] as? Int ?? 0
                
                // 根据模式设定不同的尺寸过滤标准
                var isSizeValid = false

                // 过滤小窗口
                if currentMode == .single {
                    if w > 200 && h > 500 { isSizeValid = true }
                }  else {
                    if w > 50 && h > 50 { isSizeValid = true }
                }
                
                if isSizeValid && isOnScreen == 1 {
                    if !foundTopmostValidWindow {
                        sessionWindowIDs.insert(windowID)
                        foundTopmostValidWindow = true
                    }
                    
                    // 检查是否在白名单中
                    if sessionWindowIDs.contains(windowID) {
                        
                        // 计算遮挡
                        var coveredArea: CGFloat = 0
                        let totalArea = w * h
                        for blocker in higherBlockers {
                            let intersection = rawRect.intersection(blocker)
                            if !intersection.isNull {
                                coveredArea += intersection.width * intersection.height
                            }
                        }
                        
                        let occlusionRatio = coveredArea / totalArea
                        let threshold = (currentMode == .single) ? 0.5 : 0.99
                        
                        if occlusionRatio < threshold {
                            let drawRect = CGRect(x: x, y: screenHeight - y - h, width: w, height: h)
                            visibleHoles.append(drawRect)
                            
                            if currentMode == .single {
                                break
                            }
                        }
                    }
                }
            }
            else {
                // 遮挡物判定标准
                if w > 100 && h > 100 {
                    higherBlockers.append(rawRect)
                }
            }
        }
        
        if hasFullscreenWindow {
            DispatchQueue.main.async { self.overlayWindow.orderOut(nil) }
            return
        }
        
        DispatchQueue.main.async {
            if !self.overlayWindow.isVisible {
                self.overlayWindow.makeKeyAndOrderFront(nil)
            }
            if let view = self.overlayWindow.contentView as? OverlayView {
                view.update(holes: visibleHoles, opacity: view.opacity)
            }
        }
    }
}


