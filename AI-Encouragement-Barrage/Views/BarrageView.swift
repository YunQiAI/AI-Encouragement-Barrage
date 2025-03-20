//
//  BarrageView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import SwiftUI

/// 弹幕视图 - 负责渲染弹幕
struct BarrageView: View {
    @ObservedObject var engine: BarrageEngine
    
    var body: some View {
        ZStack {
            // 透明背景
            Color.clear
            
            // 显示所有活跃的弹幕
            ForEach(engine.activeBarrages) { barrage in
                BarrageTextView(barrage: barrage, enableAnimations: engine.config.enableAnimations)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

/// 单个弹幕文本视图
struct BarrageTextView: View {
    let barrage: BarrageItem
    let enableAnimations: Bool
    
    var body: some View {
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
                enableAnimations: enableAnimations,
                animationEffect: barrage.style.animationEffect,
                animationState: barrage.animationState
            ))
    }
}

/// 弹幕动画修饰符
struct BarrageAnimationModifier: ViewModifier {
    let enableAnimations: Bool
    let animationEffect: BarrageStyle.AnimationEffect
    let animationState: BarrageItem.AnimationState
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scaleEffect)
            .offset(offsetEffect)
    }
    
    // 计算缩放效果
    private var scaleEffect: CGFloat {
        if !enableAnimations || animationEffect != .pulse {
            return 1.0
        }
        return 1.0 + 0.1 * sin(animationState.pulsePhase)
    }
    
    // 计算位移效果
    private var offsetEffect: CGSize {
        if !enableAnimations {
            return .zero
        }
        
        switch animationEffect {
        case .wave:
            let offsetY = 3 * sin(animationState.wavePhase)
            return CGSize(width: 0, height: offsetY)
        case .shake:
            return CGSize(
                width: animationState.shakeOffset.x,
                height: animationState.shakeOffset.y
            )
        case .pulse, .none:
            return .zero
        }
    }
}
