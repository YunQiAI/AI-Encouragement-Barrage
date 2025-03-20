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
    private var barrageManager: BarrageManager
    
    init() {
        // 获取主屏幕尺寸
        guard let screen = NSScreen.main else {
            fatalError("无法获取主屏幕")
        }
        
        self.barrageManager = BarrageManager(screenSize: screen.frame.size)
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
        let contentView = BarrageContentView(barrageManager: barrageManager)
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
    func addBarrage(text: String, isError: Bool = false) {
        barrageManager.addBarrage(text: text, isError: isError)
    }
    
    // 清除所有弹幕
    func clearAllBarrages() {
        barrageManager.clearAllBarrages()
    }
    
    // 设置弹幕速度
    func setSpeed(_ speed: Double) {
        barrageManager.setSpeed(speed)
    }
    
    // 设置弹幕方向
    func setDirection(_ direction: String) {
        barrageManager.setDirection(direction)
    }
    
    // 设置弹幕显示范围
    func setTravelRange(_ range: Double) {
        barrageManager.setTravelRange(range)
    }
    
    // 更新屏幕大小（例如，当屏幕分辨率改变时）
    func updateScreenSize() {
        guard let screen = NSScreen.main else { return }
        window?.setFrame(screen.frame, display: true)
        barrageManager.updateScreenSize(screen.frame.size)
    }
}

// 弹幕内容视图
struct BarrageContentView: View {
    @ObservedObject var barrageManager: BarrageManager
    
    var body: some View {
        ZStack {
            // 透明背景
            Color.clear
            
            // 显示所有活跃的弹幕
            ForEach(barrageManager.activeBarrages) { barrage in
                Text(barrage.text)
                    .font(.system(size: barrage.fontSize, weight: .bold))
                    .foregroundColor(barrage.color)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                    .position(barrage.position)
                    .opacity(barrage.opacity)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}