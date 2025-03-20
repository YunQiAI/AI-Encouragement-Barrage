//
//  AppState.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var isProcessing: Bool = false
    @Published var lastEncouragement: String = ""
    @Published var lastCaptureTime: Date? = nil
    @Published var shouldTestBarrages: Bool = false
    @Published var barrageService: BarrageService?
    
    // 当前选中的会话ID
    @Published var selectedConversationID: UUID? = nil
    
    // 新增属性：控制屏幕监控
    @Published var isScreenAnalysisActive: Bool = false {
        didSet {
            // 保存到用户默认设置
            UserDefaults.standard.set(isScreenAnalysisActive, forKey: "ScreenAnalysisActive")
            
            // 记录日志
            print("屏幕监控状态变更: \(isScreenAnalysisActive)")
        }
    }
    
    func toggleRunning() {
        isRunning.toggle()
    }
    
    func setProcessing(_ isProcessing: Bool) {
        self.isProcessing = isProcessing
    }
    
    func updateLastEncouragement(_ text: String) {
        self.lastEncouragement = text
        self.lastCaptureTime = Date()
    }
    
    func triggerTestBarrages() {
        shouldTestBarrages = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldTestBarrages = false
        }
    }
    
    // 选择会话
    func selectConversation(_ id: UUID?) {
        self.selectedConversationID = id
    }
    
    // 新增方法：切换屏幕监控状态
    func toggleScreenAnalysis() {
        isScreenAnalysisActive.toggle()
    }
    
    // 初始化时加载保存的设置
    func loadSavedSettings() {
        if UserDefaults.standard.object(forKey: "ScreenAnalysisActive") != nil {
            isScreenAnalysisActive = UserDefaults.standard.bool(forKey: "ScreenAnalysisActive")
        }
    }
}