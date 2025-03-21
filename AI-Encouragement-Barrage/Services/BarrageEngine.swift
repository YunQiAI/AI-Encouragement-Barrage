//
//  BarrageEngine.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import SwiftUI
import Combine

/// 弹幕引擎 - 负责弹幕的基本显示和移动
class BarrageEngine: ObservableObject {
    /// 当前活跃的弹幕
    @Published var activeBarrages: [BarrageItem] = []
    
    /// 屏幕尺寸
    private var screenSize: CGSize
    
    /// 动画计时器
    private var animationTimer: Timer?
    
    /// 弹幕队列
    private var barrageQueue: [String] = []
    
    /// 移动速度
    private var speed: Double = 2.0
    
    /// 弹幕轨道
    private var tracks: [Int: Date] = [:]
    
    /// 轨道数量
    private let trackCount = 15
    
    /// 轨道间隔
    private var trackHeight: CGFloat = 0
    
    /// 显示模式
    private var displayMode: String
    
    /// 初始化
    /// - Parameters:
    ///   - screenSize: 屏幕尺寸
    ///   - displayMode: 显示模式
    init(screenSize: CGSize, displayMode: String = "scattered") {
        self.screenSize = screenSize
        self.displayMode = displayMode
        self.trackHeight = (screenSize.height - 100) / CGFloat(trackCount)
        startAnimationTimer()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    // MARK: - 公共方法
    
    /// 添加弹幕
    /// - Parameter text: 弹幕文本
    func addBarrage(text: String) {
        if displayMode == "scattered" {
            addScatteredBarrage(text: text)
        } else {
            addLinearBarrage(text: text)
        }
    }
    
    /// 设置移动速度
    /// - Parameter speed: 速度值（默认2.0）
    func setSpeed(_ speed: Double) {
        self.speed = speed
    }
    
    /// 清除所有弹幕
    func clearAllBarrages() {
        activeBarrages.removeAll()
        barrageQueue.removeAll()
    }
    
    /// 更新屏幕大小
    /// - Parameter size: 新的屏幕尺寸
    func updateScreenSize(_ size: CGSize) {
        self.screenSize = size
        self.trackHeight = (size.height - 100) / CGFloat(trackCount)
    }
    
    /// 更新显示模式
    /// - Parameter mode: 新的显示模式
    func updateDisplayMode(_ mode: String) {
        self.displayMode = mode
    }
    
    // MARK: - 私有方法
    
    /// 添加线性弹幕（传统从右到左）
    /// - Parameter text: 弹幕文本
    private func addLinearBarrage(text: String) {
        // 获取可用轨道
        let trackIndex = getAvailableTrack()
        
        // 计算弹幕Y坐标
        let yPosition = 50 + (trackHeight * CGFloat(trackIndex))
        
        // 随机颜色
        let colors: [Color] = [.white, .yellow, .green, .cyan, .orange]
        let color = colors.randomElement() ?? .white
        
        // 随机字体大小
        let fontSize = CGFloat.random(in: 14...20)
        
        let position = CGPoint(
            x: screenSize.width,
            y: yPosition
        )
        
        let barrage = BarrageItem(
            id: UUID(),
            text: text,
            position: position,
            color: color,
            fontSize: fontSize,
            opacity: 1.0,
            createdAt: Date(),
            trackIndex: trackIndex,
            isStatic: false
        )
        
        // 标记轨道为已使用
        tracks[trackIndex] = Date()
        
        DispatchQueue.main.async {
            self.activeBarrages.append(barrage)
        }
    }
    
    /// 添加分散弹幕（全屏随机位置）
    /// - Parameter text: 弹幕文本
    private func addScatteredBarrage(text: String) {
        // 随机位置（避开屏幕边缘）
        let margin: CGFloat = 50
        let xPosition = CGFloat.random(in: (margin)...(screenSize.width - margin))
        let yPosition = CGFloat.random(in: (margin)...(screenSize.height - margin))
        
        // 随机颜色
        let colors: [Color] = [.white, .yellow, .green, .cyan, .orange, .pink, .purple]
        let color = colors.randomElement() ?? .white
        
        // 随机字体大小
        let fontSize = CGFloat.random(in: 16...24)
        
        let position = CGPoint(x: xPosition, y: yPosition)
        
        let barrage = BarrageItem(
            id: UUID(),
            text: text,
            position: position,
            color: color,
            fontSize: fontSize,
            opacity: 1.0,
            createdAt: Date(),
            trackIndex: -1, // 不使用轨道
            isStatic: true  // 静态显示
        )
        
        DispatchQueue.main.async {
            self.activeBarrages.append(barrage)
            
            // 设置定时器，3秒后淡出并移除
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                self?.fadeOutBarrage(barrage.id)
            }
        }
    }
    
    /// 淡出并移除弹幕
    /// - Parameter id: 弹幕ID
    private func fadeOutBarrage(_ id: UUID) {
        // 找到对应的弹幕
        guard let index = activeBarrages.firstIndex(where: { $0.id == id }) else { return }
        
        // 开始淡出动画
        withAnimation(.easeOut(duration: 1.0)) {
            activeBarrages[index].opacity = 0.0
        }
        
        // 1秒后移除弹幕
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.activeBarrages.removeAll { $0.id == id }
            }
        }
    }
    
    /// 启动动画计时器
    private func startAnimationTimer() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { [weak self] _ in
            self?.updateBarragePositions()
        }
    }
    
    /// 获取可用轨道
    private func getAvailableTrack() -> Int {
        // 检查是否有空闲轨道
        for i in 0..<trackCount {
            // 如果轨道未使用或者上次使用时间已经超过2秒
            if tracks[i] == nil || Date().timeIntervalSince(tracks[i]!) > 2.0 {
                return i
            }
        }
        
        // 如果所有轨道都在使用中，随机选择一个
        return Int.random(in: 0..<trackCount)
    }
    
    /// 更新弹幕位置
    private func updateBarragePositions() {
        DispatchQueue.main.async {
            var updatedBarrages: [BarrageItem] = []
            
            for var barrage in self.activeBarrages {
                // 只移动非静态弹幕
                if !barrage.isStatic {
                    // 向左移动弹幕
                    barrage.position.x -= self.speed
                    
                    // 如果弹幕还在屏幕内，保留它
                    if barrage.position.x > -200 { // 考虑文本长度，给一些余量
                        updatedBarrages.append(barrage)
                    }
                } else {
                    // 静态弹幕直接保留
                    updatedBarrages.append(barrage)
                }
            }
            
            self.activeBarrages = updatedBarrages
        }
    }
}

// MARK: - 弹幕项模型
struct BarrageItem: Identifiable {
    let id: UUID
    let text: String
    var position: CGPoint
    let color: Color
    let fontSize: CGFloat
    var opacity: Double
    let createdAt: Date
    let trackIndex: Int
    let isStatic: Bool // 是否为静态弹幕（不移动）
}
