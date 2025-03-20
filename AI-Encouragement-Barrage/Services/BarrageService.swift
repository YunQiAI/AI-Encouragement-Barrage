//
//  BarrageService.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import SwiftUI
import SwiftData

/// 弹幕服务 - 负责弹幕的高级管理和与其他服务的集成
@MainActor
class BarrageService: ObservableObject {
    /// 弹幕窗口
    private var barrageWindow: BarrageOverlayWindow
    
    /// 语音合成器
    private var speechSynthesizer: SpeechSynthesizer?
    
    /// 是否启用语音
    @Published var speechEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(speechEnabled, forKey: "SpeechEnabled")
        }
    }
    
    /// 是否显示弹幕
    @Published var isVisible: Bool = true {
        didSet {
            if isVisible {
                barrageWindow.show()
            } else {
                barrageWindow.hide()
            }
            UserDefaults.standard.set(isVisible, forKey: "BarrageVisible")
        }
    }
    
    /// 历史消息
    @Published var messageHistory: [EncouragementMessage] = []
    
    /// 消息模型上下文
    private var modelContext: ModelContext?
    
    /// 初始化
    /// - Parameter modelContext: SwiftData模型上下文（可选）
    init(modelContext: ModelContext? = nil) {
        // 创建弹幕窗口
        self.barrageWindow = BarrageOverlayWindow()
        
        // 创建语音合成器
        self.speechSynthesizer = SpeechSynthesizer()
        
        // 设置模型上下文
        self.modelContext = modelContext
        
        // 加载设置
        loadSettings()
        
        // 加载历史消息
        Task {
            await loadMessageHistory()
        }
        
        // 显示或隐藏弹幕窗口
        if isVisible {
            barrageWindow.show()
        } else {
            barrageWindow.hide()
        }
    }
    
    // MARK: - 公共方法
    
    /// 显示弹幕
    /// - Parameters:
    ///   - text: 弹幕文本
    ///   - type: 弹幕类型
    ///   - speak: 是否朗读
    ///   - saveToHistory: 是否保存到历史记录
    ///   - context: 上下文信息
    func showBarrage(
        text: String,
        type: BarrageItem.BarrageType = .normal,
        speak: Bool = false,
        saveToHistory: Bool = true,
        context: String? = nil
    ) {
        // 显示弹幕
        barrageWindow.addBarrage(text: text, type: type)
        
        // 朗读文本
        if speak && speechEnabled, let synthesizer = speechSynthesizer {
            synthesizer.speak(text: text)
        }
        
        // 保存到历史记录
        if saveToHistory {
            Task {
                await saveMessage(text: text, context: context)
            }
        }
    }
    
    /// 显示多条弹幕
    /// - Parameters:
    ///   - text: 文本内容
    ///   - type: 弹幕类型
    ///   - speak: 是否朗读
    ///   - saveToHistory: 是否保存到历史记录
    ///   - context: 上下文信息
    func showMultipleBarrages(
        text: String,
        type: BarrageItem.BarrageType = .normal,
        speak: Bool = false,
        saveToHistory: Bool = true,
        context: String? = nil
    ) {
        // 显示多条弹幕
        barrageWindow.addMultipleBarrages(text: text, type: type)
        
        // 朗读文本
        if speak && speechEnabled, let synthesizer = speechSynthesizer {
            synthesizer.speak(text: text)
        }
        
        // 保存到历史记录
        if saveToHistory {
            Task {
                await saveMessage(text: text, context: context)
            }
        }
    }
    
    /// 处理流式响应
    /// - Parameter partial: 部分响应文本
    func processStreamingResponse(_ partial: String) {
        barrageWindow.processStreamingResponse(partial)
    }
    
    /// 清除所有弹幕
    func clearAllBarrages() {
        barrageWindow.clearAllBarrages()
        speechSynthesizer?.stop()
    }
    
    /// 更新屏幕大小
    func updateScreenSize() {
        barrageWindow.updateScreenSize()
    }
    
    /// 获取弹幕配置
    func getBarrageConfig() -> BarrageConfig {
        return barrageWindow.getConfig()
    }
    
    /// 设置弹幕配置
    /// - Parameter config: 弹幕配置
    func setBarrageConfig(config: BarrageConfig) {
        // 设置速度
        barrageWindow.setSpeed(config.speed)
        
        // 设置方向
        barrageWindow.setDirection(config.direction.rawValue)
        
        // 设置显示范围
        barrageWindow.setTravelRange(config.travelRange)
        
        // 设置密度
        barrageWindow.setDensity(config.density)
        
        // 设置样式
        barrageWindow.setStylePreset(config.defaultStyle.rawValue)
        
        // 设置是否使用随机样式
        barrageWindow.setUseRandomStyle(config.useRandomStyle)
        
        // 设置是否启用动画效果
        barrageWindow.setEnableAnimations(config.enableAnimations)
    }
    
    // MARK: - 私有方法
    
    /// 加载设置
    private func loadSettings() {
        // 加载语音设置
        speechEnabled = UserDefaults.standard.bool(forKey: "SpeechEnabled")
        
        // 加载弹幕可见性设置
        if UserDefaults.standard.object(forKey: "BarrageVisible") == nil {
            // 如果设置不存在，默认为可见
            isVisible = true
        } else {
            isVisible = UserDefaults.standard.bool(forKey: "BarrageVisible")
        }
    }
    
    /// 加载历史消息
    private func loadMessageHistory() async {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<EncouragementMessage>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            messageHistory = try modelContext.fetch(descriptor)
        } catch {
            print("加载历史消息失败: \(error.localizedDescription)")
        }
    }
    
    /// 保存消息到历史记录
    private func saveMessage(text: String, context: String?) async {
        guard let modelContext = modelContext else { return }
        
        // 创建新消息
        let message = EncouragementMessage(text: text, context: context)
        
        // 添加到内存中的历史记录
        messageHistory.insert(message, at: 0)
        if messageHistory.count > 100 {
            messageHistory.removeLast()
        }
        
        // 保存到数据库
        modelContext.insert(message)
        
        do {
            try modelContext.save()
        } catch {
            print("保存消息失败: \(error.localizedDescription)")
        }
    }
}
