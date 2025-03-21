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
    /// 语音服务
    private var speechService: SpeechService
    /// 设置
    private var settings: AppSettings
    /// 弹幕队列
    private var barrageQueue: [String] = []
    /// 是否正在处理弹幕
    private var isProcessingBarrage: Bool = false
    
    /// 初始化
    init(appState: AppState, settings: AppSettings) {
        self.appState = appState
        self.settings = settings
        self.speechService = SpeechService()
        print("BarrageService: currentContext = \(appState.currentContext)")
        self.barrageWindow = BarrageOverlayWindow()
        self.barrageWindow.show()
    }
    
    /// 显示弹幕
    /// - Parameter text: 弹幕文本
    func showBarrage(text: String) {
        // 将弹幕添加到队列
        barrageQueue.append(text)
        
        // 如果没有正在处理的弹幕，开始处理队列
        if !isProcessingBarrage {
            processNextBarrage()
        }
    }
    
    /// 处理下一条弹幕
    private func processNextBarrage() {
        // 如果队列为空，标记为未处理状态并返回
        guard !barrageQueue.isEmpty else {
            isProcessingBarrage = false
            return
        }
        
        // 标记为正在处理
        isProcessingBarrage = true
        
        // 获取队列中的第一条弹幕
        let text = barrageQueue.removeFirst()
        
        // 显示弹幕
        barrageWindow.addBarrage(text: text)
        
        // 如果启用了语音，播放语音
        if settings.speechEnabled {
            speechService.speak(text) {
                // 语音播放完成后，处理下一条弹幕
                Task { @MainActor in
                    self.processNextBarrage()
                }
            }
        } else {
            // 如果未启用语音，等待一小段时间后处理下一条弹幕
            Task {
                try? await Task.sleep(nanoseconds: 800_000_000) // 等待0.8秒
                await MainActor.run {
                    self.processNextBarrage()
                }
            }
        }
    }
    
    /// 清除所有弹幕
    func clearAllBarrages() {
        barrageWindow.clearAllBarrages()
        barrageQueue.removeAll()
        isProcessingBarrage = false
        speechService.stopSpeaking()
    }
    
    /// 更新设置
    func updateSettings(_ newSettings: AppSettings) {
        self.settings = newSettings
    }
}
