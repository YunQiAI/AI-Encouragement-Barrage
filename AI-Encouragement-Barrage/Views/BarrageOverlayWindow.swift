//
//  BarrageOverlayWindow.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import SwiftUI
import AppKit

// 弹幕覆盖窗口
class BarrageOverlayWindow {
    private var window: NSWindow?
    private var engine: BarrageEngine
    
    init() {
        // 获取主屏幕尺寸
        guard let screen = NSScreen.main else {
            fatalError("无法获取主屏幕")
        }
        
        self.engine = BarrageEngine(screenSize: screen.frame.size)
        setupWindow()
    }
    
    // 设置窗口
    private func setupWindow() {
        guard let screen = NSScreen.main else { return }
        
        // 创建一个全屏透明窗口
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口属性
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .screenSaver // 设置为屏幕保护程序级别，确保显示在大多数应用程序之上
        window.ignoresMouseEvents = true // 忽略鼠标事件，使点击可以穿透到下面的窗口
        window.collectionBehavior = [.canJoinAllSpaces, .stationary] // 在所有工作区显示，并且不随工作区切换而移动
        
        // 设置内容视图
        let contentView = BarrageContentView(engine: engine)
        window.contentView = NSHostingView(rootView: contentView)
        
        self.window = window
    }
    
    // 显示窗口
    func show() {
        window?.orderFront(nil)
    }
    
    // 隐藏窗口
    func hide() {
        window?.orderOut(nil)
    }
    
    // 添加弹幕
    func addBarrage(text: String, type: BarrageItem.BarrageType = .normal) {
        engine.addBarrage(text: text, type: type)
    }
    
    // 添加多条弹幕
    func addMultipleBarrages(text: String, type: BarrageItem.BarrageType = .normal) {
        engine.addMultipleBarrages(text: text, type: type)
    }
    
    // 处理流式响应
    func processStreamingResponse(_ partial: String) {
        engine.processStreamingResponse(partial)
    }
    
    // 清除所有弹幕
    func clearAllBarrages() {
        engine.clearAllBarrages()
    }
    
    // 设置弹幕速度
    func setSpeed(_ speed: Double) {
        var config = engine.config
        config.speed = speed
        engine.config = config
    }
    
    // 设置弹幕方向
    func setDirection(_ direction: String) {
        var config = engine.config
        if let dir = BarrageConfig.Direction.allCases.first(where: { $0.rawValue == direction }) {
            config.direction = dir
            engine.config = config
        }
    }
    
    // 设置弹幕显示范围
    func setTravelRange(_ range: Double) {
        var config = engine.config
        config.travelRange = range
        engine.config = config
    }
    
    // 设置弹幕密度
    func setDensity(_ density: Double) {
        var config = engine.config
        config.density = density
        engine.config = config
    }
    
    // 设置弹幕样式
    func setStylePreset(_ preset: String) {
        var config = engine.config
        if let stylePreset = BarrageConfig.StylePreset.allCases.first(where: { $0.rawValue == preset }) {
            config.defaultStyle = stylePreset
            engine.config = config
        }
    }
    
    // 设置是否使用随机样式
    func setUseRandomStyle(_ useRandom: Bool) {
        var config = engine.config
        config.useRandomStyle = useRandom
        engine.config = config
    }
    
    // 设置是否启用动画效果
    func setEnableAnimations(_ enable: Bool) {
        var config = engine.config
        config.enableAnimations = enable
        engine.config = config
    }
    
    // 更新屏幕大小（例如，当屏幕分辨率改变时）
    func updateScreenSize() {
        guard let screen = NSScreen.main else { return }
        window?.setFrame(screen.frame, display: true)
        engine.updateScreenSize(screen.frame.size)
    }
    
    // 获取当前配置
    func getConfig() -> BarrageConfig {
        return engine.config
    }
}

// 弹幕内容视图
struct BarrageContentView: View {
    @ObservedObject var engine: BarrageEngine
    
    var body: some View {
        ZStack {
            // 透明背景
            Color.clear
            
            // 显示所有活跃的弹幕
            ForEach(engine.activeBarrages) { barrage in
                Text(barrage.text)
                    .font(.system(size: barrage.style.fontSize, weight: .bold))
                    .foregroundColor(barrage.style.color)
                    .shadow(
                        color: barrage.style.shadowColor,
                        radius: barrage.style.shadowRadius,
                        x: barrage.style.shadowOffset.x,
                        y: barrage.style.shadowOffset.y
                    )
                    .position(barrage.position)
                    .opacity(barrage.opacity * barrage.style.opacity)
                    .modifier(BarrageAnimationModifier(
                        enableAnimations: engine.config.enableAnimations,
                        animationEffect: barrage.style.animationEffect,
                        animationState: barrage.animationState
                    ))
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}