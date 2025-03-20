//
//  BarrageStyle.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import SwiftUI

/// 弹幕样式定义
struct BarrageStyle: Equatable, Hashable {
    /// 弹幕字体大小
    var fontSize: CGFloat
    
    /// 弹幕颜色
    var color: Color
    
    /// 弹幕阴影效果
    var shadowRadius: CGFloat
    var shadowColor: Color
    var shadowOffset: CGPoint
    
    /// 弹幕透明度
    var opacity: Double
    
    /// 弹幕动画效果
    var animationEffect: AnimationEffect
    
    /// 创建默认样式
    static func defaultStyle() -> BarrageStyle {
        return BarrageStyle(
            fontSize: 22,
            color: .white,
            shadowRadius: 2,
            shadowColor: .black.opacity(0.5),
            shadowOffset: CGPoint(x: 1, y: 1),
            opacity: 1.0,
            animationEffect: .none
        )
    }
    
    /// 创建错误样式
    static func errorStyle() -> BarrageStyle {
        return BarrageStyle(
            fontSize: 22,
            color: .red,
            shadowRadius: 2,
            shadowColor: .black.opacity(0.5),
            shadowOffset: CGPoint(x: 1, y: 1),
            opacity: 1.0,
            animationEffect: .none
        )
    }
    
    /// 创建随机样式
    static func randomStyle() -> BarrageStyle {
        return BarrageStyle(
            fontSize: CGFloat.random(in: 18...28),
            color: Color(hue: Double.random(in: 0...1), saturation: 0.7, brightness: 0.9),
            shadowRadius: 2,
            shadowColor: .black.opacity(0.5),
            shadowOffset: CGPoint(x: 1, y: 1),
            opacity: 1.0,
            animationEffect: .none
        )
    }
    
    /// 弹幕动画效果
    enum AnimationEffect: String, CaseIterable, Identifiable {
        case none = "无"
        case pulse = "脉冲"
        case wave = "波浪"
        case shake = "抖动"
        
        var id: String { self.rawValue }
    }
}