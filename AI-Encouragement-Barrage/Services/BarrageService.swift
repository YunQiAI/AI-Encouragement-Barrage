//
//  BarrageService.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import SwiftUI
import SwiftData

/// 弹幕服务 - 负责弹幕的显示管理
@MainActor
class BarrageService: ObservableObject {
    /// 弹幕窗口
    private var barrageWindow: BarrageOverlayWindow
    /// 应用状态
    private var appState: AppState
    
    /// 初始化
    init(appState: AppState) {
        self.appState = appState
        print("BarrageService: currentContext = \(appState.currentContext)")
        self.barrageWindow = BarrageOverlayWindow()
        self.barrageWindow.show()
    }
    
    /// 显示弹幕
    /// - Parameter text: 弹幕文本
    func showBarrage(text: String) {
        barrageWindow.addBarrage(text: text)
    }
    
    /// 清除所有弹幕
    func clearAllBarrages() {
        barrageWindow.clearAllBarrages()
    }
}
