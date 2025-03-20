//
//  BarrageItem.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import SwiftUI
/// 弹幕项
struct BarrageItem: Identifiable, Equatable {
    
    static func == (lhs: BarrageItem, rhs: BarrageItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// 唯一标识符
    let id = UUID()
    
    
    /// 弹幕文本内容
    let text: String
    
    /// 弹幕位置
    var position: CGPoint
    
    /// 弹幕透明度
    var opacity: Double = 1.0
    
    /// 弹幕移动方向
    var direction: BarrageConfig.Direction.ActualDirection
    
    /// 弹幕样式
    var style: BarrageStyle
    
    /// 弹幕创建时间
    let createdAt: Date
    
    /// 弹幕预计存活时间（秒）
    let lifetime: Double
    
    /// 弹幕类型
    var type: BarrageType
    
    /// 弹幕动画状态
    var animationState: AnimationState = AnimationState()
    
    /// 创建弹幕
    /// - Parameters:
    ///   - text: 弹幕文本
    ///   - screenSize: 屏幕尺寸
    ///   - config: 弹幕配置
    ///   - type: 弹幕类型
    /// - Returns: 弹幕项
    static func create(
        text: String,
        screenSize: CGSize,
        config: BarrageConfig,
        type: BarrageType = .normal
    ) -> BarrageItem {
        // 确定方向
        let direction = config.direction.getActualDirection()
        
        // 确定起始位置
        let startX: CGFloat
        if direction == .leftToRight {
            startX = -200
        } else {
            startX = screenSize.width + 200
        }
        
        // 随机Y坐标
        let y = CGFloat.random(in: 50...(screenSize.height - 100))
        
        // 确定样式
        let style: BarrageStyle
        switch type {
        case .normal:
            if config.useRandomStyle {
                style = BarrageStyle.randomStyle()
            } else {
                style = config.defaultStyle.getStyle()
            }
        case .error:
            style = BarrageStyle.errorStyle()
        case .system:
            style = BarrageStyle(
                fontSize: 20,
                color: .gray,
                shadowRadius: 1,
                shadowColor: .black.opacity(0.3),
                shadowOffset: CGPoint(x: 1, y: 1),
                opacity: 0.8,
                animationEffect: .none
            )
        case .highlight:
            style = BarrageStyle(
                fontSize: 24,
                color: .yellow,
                shadowRadius: 4,
                shadowColor: .black.opacity(0.6),
                shadowOffset: CGPoint(x: 1, y: 1),
                opacity: 1.0,
                animationEffect: .pulse
            )
        }
        
        return BarrageItem(
            text: text,
            position: CGPoint(x: startX, y: y),
            direction: direction,
            style: style,
            createdAt: Date(),
            lifetime: config.lifetime,
            type: type
        )
    }
    
    /// 弹幕类型
    enum BarrageType {
        case normal    // 普通弹幕
        case error     // 错误弹幕
        case system    // 系统弹幕
        case highlight // 高亮弹幕
    }
    
    /// 动画状态
    struct AnimationState {
        var pulsePhase: Double = 0.0
        var wavePhase: Double = 0.0
        var shakeOffset: CGPoint = .zero
        
        /// 更新动画状态
        mutating func update(effect: BarrageStyle.AnimationEffect) {
            switch effect {
            case .pulse:
                pulsePhase += 0.05
                if pulsePhase > .pi * 2 {
                    pulsePhase -= .pi * 2
                }
            case .wave:
                wavePhase += 0.1
                if wavePhase > .pi * 2 {
                    wavePhase -= .pi * 2
                }
            case .shake:
                shakeOffset = CGPoint(
                    x: CGFloat.random(in: -2...2),
                    y: CGFloat.random(in: -1...1)
                )
            case .none:
                break
            }
        }
        
        /// 获取当前动画修饰
        func getModifier(for effect: BarrageStyle.AnimationEffect) -> any ViewModifier {
            switch effect {
            case .pulse:
                let scale = 1.0 + 0.1 * sin(pulsePhase)
                return ScaleModifier(scale: scale)
            case .wave:
                let offsetY = 3 * sin(wavePhase)
                return OffsetModifier(offset: CGSize(width: 0, height: offsetY))
            case .shake:
                return OffsetModifier(offset: CGSize(width: shakeOffset.x, height: shakeOffset.y))
            case .none:
                return EmptyModifier()
            }
        }
    }
}

// MARK: - 辅助修饰符

struct ScaleModifier: ViewModifier {
    let scale: Double
    
    func body(content: Content) -> some View {
        content.scaleEffect(scale)
    }
}

struct OffsetModifier: ViewModifier {
    let offset: CGSize
    
    func body(content: Content) -> some View {
        content.offset(offset)
    }
}

struct EmptyModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}