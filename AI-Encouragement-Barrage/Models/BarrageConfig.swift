//
//  BarrageConfig.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import SwiftUI

/// 弹幕配置
struct BarrageConfig: Codable, Equatable {
    /// 弹幕移动速度
    var speed: Double = 1.0
    
    /// 弹幕移动方向
    var direction: Direction = .rightToLeft
    
    /// 弹幕显示范围（屏幕宽度的百分比）
    var travelRange: Double = 1.0
    
    /// 弹幕密度（每秒最大弹幕数）
    var density: Double = 5.0
    
    /// 弹幕存活时间（秒）
    var lifetime: Double = 8.0
    
    /// 弹幕样式设置
    var defaultStyle: StylePreset = .colorful
    
    /// 是否启用随机样式
    var useRandomStyle: Bool = true
    
    /// 是否启用动画效果
    var enableAnimations: Bool = true
    
    /// 弹幕移动方向
    enum Direction: String, CaseIterable, Identifiable, Codable {
        case leftToRight = "从左到右"
        case rightToLeft = "从右到左"
        case bidirectional = "双向"
        
        var id: String { self.rawValue }
        
        /// 随机选择一个方向
        static func random() -> Direction {
            return Bool.random() ? .leftToRight : .rightToLeft
        }
        
        /// 获取实际方向（对于双向模式，随机选择一个方向）
        func getActualDirection() -> ActualDirection {
            switch self {
            case .leftToRight:
                return .leftToRight
            case .rightToLeft:
                return .rightToLeft
            case .bidirectional:
                return Bool.random() ? .leftToRight : .rightToLeft
            }
        }
        
        /// 实际方向（不包含双向选项）
        enum ActualDirection {
            case leftToRight
            case rightToLeft
        }
    }
    
    /// 预设样式
    enum StylePreset: String, CaseIterable, Identifiable, Codable {
        case simple = "简约"
        case colorful = "彩色"
        case neon = "霓虹"
        case elegant = "优雅"
        case bold = "醒目"
        
        var id: String { self.rawValue }
        
        /// 获取预设样式对应的BarrageStyle
        func getStyle() -> BarrageStyle {
            switch self {
            case .simple:
                return BarrageStyle(
                    fontSize: 20,
                    color: .white,
                    shadowRadius: 1,
                    shadowColor: .black.opacity(0.3),
                    shadowOffset: CGPoint(x: 1, y: 1),
                    opacity: 0.9,
                    animationEffect: .none
                )
            case .colorful:
                return BarrageStyle(
                    fontSize: 22,
                    color: Color(hue: Double.random(in: 0...1), saturation: 0.7, brightness: 0.9),
                    shadowRadius: 2,
                    shadowColor: .black.opacity(0.5),
                    shadowOffset: CGPoint(x: 1, y: 1),
                    opacity: 1.0,
                    animationEffect: .none
                )
            case .neon:
                return BarrageStyle(
                    fontSize: 24,
                    color: .white,
                    shadowRadius: 8,
                    shadowColor: Color(hue: Double.random(in: 0...1), saturation: 1.0, brightness: 1.0),
                    shadowOffset: CGPoint(x: 0, y: 0),
                    opacity: 1.0,
                    animationEffect: .pulse
                )
            case .elegant:
                return BarrageStyle(
                    fontSize: 20,
                    color: Color(white: 0.9),
                    shadowRadius: 3,
                    shadowColor: .black.opacity(0.2),
                    shadowOffset: CGPoint(x: 0, y: 2),
                    opacity: 0.85,
                    animationEffect: .none
                )
            case .bold:
                return BarrageStyle(
                    fontSize: 26,
                    color: .yellow,
                    shadowRadius: 4,
                    shadowColor: .black.opacity(0.7),
                    shadowOffset: CGPoint(x: 2, y: 2),
                    opacity: 1.0,
                    animationEffect: .shake
                )
            }
        }
    }
}