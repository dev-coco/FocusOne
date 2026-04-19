import Cocoa

class OverlayWindow: NSWindow {
    init() {
        // 先初始化无边框窗口
        super.init(
            contentRect: .zero, // 先给 0，后面会自动调整
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        // 透明窗口
        self.isOpaque = false
        // 背景设为 clear，实际遮罩颜色由 contentView 绘制
        self.backgroundColor = .clear
        // 将窗口置于浮动层级，通常高于应用窗口
        self.level = .floating
        // 忽略鼠标事件，可以穿过遮罩点击
        self.ignoresMouseEvents = true
        // 允许出现在所有空间、避免被切换等行为
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        // 绘制黑色背景与高亮
        self.contentView = OverlayView()
        
        // 初始化后尝试一次适配屏幕尺寸
        self.fitScreen()
    }
    
    // 强制将窗口尺寸设置为主屏幕尺寸
    func fitScreen() {
        if let screen = NSScreen.main {
            // 调整窗口大小并刷新显示
            self.setFrame(screen.frame, display: true)
        }
    }
}

// 自定义视图负责绘制遮罩和区域高亮
class OverlayView: NSView {
    // 存放需要抠出的矩形区域
    var holes: [CGRect] = []
     // 遮罩的亮度，0.0~1.0
    var opacity: CGFloat = 0.6
    
    // 更新 holes 与 opacity 并标记需要重绘
    func update(holes: [CGRect], opacity: CGFloat) {
        self.holes = holes
        self.opacity = opacity
        self.needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // 先清空画布，防止颜色在持续绘制时叠加
        NSColor.clear.set()
        dirtyRect.fill(using: .copy)
        
        // 绘制遮罩
        NSColor.black.withAlphaComponent(opacity).setFill()
        dirtyRect.fill()
        
        // 使用复合绘制模式区域高亮
        NSGraphicsContext.current?.saveGraphicsState()
        NSGraphicsContext.current?.compositingOperation = .destinationOut
        
        NSColor.black.setFill()
        for hole in holes {
            NSBezierPath(rect: hole).fill()
        }
        
        NSGraphicsContext.current?.restoreGraphicsState()
    }
}
