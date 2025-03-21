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
    
    /// 屏幕垂直可用区域（中间80%）
    private var verticalUsableArea: (min: CGFloat, max: CGFloat) = (0, 0)
    
    /// 初始化
    /// - Parameters:
    ///   - screenSize: 屏幕尺寸
    init(screenSize: CGSize) {
        self.screenSize = screenSize
        
        // 修改：减小边距百分比，使用更多屏幕空间
        let marginPercent: CGFloat = 0.05 // 上下各留出5%
        self.verticalUsableArea = (
            min: screenSize.height * marginPercent,
            max: screenSize.height * (1 - marginPercent)
        )
        
        // 计算轨道高度
        let usableHeight = verticalUsableArea.max - verticalUsableArea.min
        self.trackHeight = usableHeight / CGFloat(trackCount)
        
        startAnimationTimer()
    }
    
    deinit {
        animationTimer?.invalidate()
    }
    
    // MARK: - 公共方法
    
    /// 添加弹幕
    /// - Parameter text: 弹幕文本
    func addBarrage(text: String) {
        // 获取可用轨道
        let trackIndex = getAvailableTrack()
        
        // 修改：对Y位置添加随机偏移，使同一轨道内的弹幕高度也有变化
        let baseYPosition = verticalUsableArea.min + (trackHeight * CGFloat(trackIndex))
        let yOffset = CGFloat.random(in: -trackHeight * 0.2...trackHeight * 0.2)
        let yPosition = baseYPosition + yOffset
        
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
            trackIndex: trackIndex
        )
        
        // 标记轨道为已使用
        tracks[trackIndex] = Date()
        
        DispatchQueue.main.async {
            self.activeBarrages.append(barrage)
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
        
        // 修改：与初始化保持一致，减小边距百分比
        let marginPercent: CGFloat = 0.05 // 上下各留出5%
        self.verticalUsableArea = (
            min: size.height * marginPercent,
            max: size.height * (1 - marginPercent)
        )
        
        // 重新计算轨道高度
        let usableHeight = verticalUsableArea.max - verticalUsableArea.min
        self.trackHeight = usableHeight / CGFloat(trackCount)
    }
    
    // MARK: - 私有方法
    
    /// 启动动画计时器
    private func startAnimationTimer() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { [weak self] _ in
            self?.updateBarragePositions()
        }
    }
    
    /// 获取可用轨道
    private func getAvailableTrack() -> Int {
        // 修改：完全随机选择轨道，确保垂直分布更均匀
        // 替代解决方案
        var weights = Array(repeating: 1.0, count: trackCount)
        let now = Date()

        for i in 0..<trackCount {
            if let lastUsed = tracks[i] {
                let timeSince = now.timeIntervalSince(lastUsed)
                if timeSince < 3.0 {
                    weights[i] = max(0.1, timeSince / 3.0)
                }
            } else {
                weights[i] = 2.0
            }
        }
        
        // 根据权重随机选择轨道
        let totalWeight = weights.reduce(0, +)
        var randomValue = Double.random(in: 0..<totalWeight)
        
        for i in 0..<trackCount {
            randomValue -= weights[i]
            if randomValue < 0 {
                return i
            }
        }
        
        return Int.random(in: 0..<trackCount)
    }
    
    /// 更新弹幕位置
    private func updateBarragePositions() {
        DispatchQueue.main.async {
            var updatedBarrages: [BarrageItem] = []
            
            for var barrage in self.activeBarrages {
                // 向左移动弹幕
                barrage.position.x -= self.speed
                
                // 如果弹幕还在屏幕内，保留它
                if barrage.position.x > -200 { // 考虑文本长度，给一些余量
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
}
