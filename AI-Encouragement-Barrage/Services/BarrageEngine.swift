//
//  BarrageEngine.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import SwiftUI
import Combine

/// 弹幕引擎 - 负责弹幕的生成、管理和动画
class BarrageEngine: ObservableObject {
    /// 当前活跃的弹幕
    @Published var activeBarrages: [BarrageItem] = []
    
    /// 弹幕配置
    @Published var config: BarrageConfig {
        didSet {
            saveConfig()
        }
    }
    
    /// 屏幕尺寸
    private var screenSize: CGSize
    
    /// 动画计时器
    private var animationTimer: Timer?
    
    /// 弹幕队列
    private var barrageQueue: [QueuedBarrage] = []
    
    /// 队列处理计时器
    private var queueTimer: Timer?
    
    /// 上次添加弹幕的时间
    private var lastBarrageTime = Date()
    
    /// 是否暂停
    private var isPaused: Bool = false
    
    /// 初始化
    /// - Parameter screenSize: 屏幕尺寸
    init(screenSize: CGSize) {
        self.screenSize = screenSize
        self.config = BarrageConfig() // 先使用默认配置
        self.isPaused = false
        self.animationTimer = nil
        self.queueTimer = nil
        self.lastBarrageTime = Date()
        self.barrageQueue = []
        self.activeBarrages = []
        
        // 现在所有属性已初始化，可以安全调用 loadConfig
        if let savedConfig = self.loadConfig() {
            self.config = savedConfig
        }
        
        // 启动计时器
        startAnimationTimer()
        startQueueTimer()
    }
    
    deinit {
        animationTimer?.invalidate()
        queueTimer?.invalidate()
    }
    
    // MARK: - 公共方法
    
    /// 添加弹幕
    /// - Parameters:
    ///   - text: 弹幕文本
    ///   - type: 弹幕类型
    ///   - immediate: 是否立即显示（不经过队列）
    func addBarrage(text: String, type: BarrageItem.BarrageType = .normal, immediate: Bool = false) {
        if immediate {
            createAndAddBarrage(text: text, type: type)
        } else {
            // 添加到队列
            let queuedBarrage = QueuedBarrage(text: text, isError: false, shouldSpeak: false, completion: nil)
            barrageQueue.append(queuedBarrage)
        }
    }
    
    /// 添加多条弹幕
    /// - Parameters:
    ///   - text: 文本内容
    ///   - type: 弹幕类型
    func addMultipleBarrages(text: String, type: BarrageItem.BarrageType = .normal) {
        // 将文本按句子分割
        let sentences = splitTextIntoSentences(text)
        
        // 为每个句子创建一个弹幕
        for sentence in sentences {
            addBarrage(text: sentence, type: type)
        }
    }
    
    /// 处理流式响应
    /// - Parameter partial: 部分响应文本
    func processStreamingResponse(_ partial: String) {
        // 分割文本
        let sentences = splitTextIntoSentences(partial)
        
        // 只处理非空句子
        for sentence in sentences where !sentence.isEmpty {
            addBarrage(text: sentence, immediate: true)
        }
    }
    
    /// 清除所有弹幕
    func clearAllBarrages() {
        activeBarrages.removeAll()
        barrageQueue.removeAll()
    }
    
    /// 暂停/恢复弹幕
    /// - Parameter paused: 是否暂停
    func setPaused(_ paused: Bool) {
        isPaused = paused
    }
    
    /// 更新屏幕大小
    /// - Parameter size: 新的屏幕尺寸
    func updateScreenSize(_ size: CGSize) {
        self.screenSize = size
    }
    
    // MARK: - 私有方法
    
    /// 创建并添加弹幕
    private func createAndAddBarrage(text: String, type: BarrageItem.BarrageType) {
        // 检查弹幕密度限制
        let now = Date()
        let timeSinceLastBarrage = now.timeIntervalSince(lastBarrageTime)
        let minInterval = 1.0 / config.density
        
        if timeSinceLastBarrage < minInterval {
            // 如果添加太频繁，加入队列
            let queuedBarrage = QueuedBarrage(text: text, isError: false, shouldSpeak: false, completion: nil)
            barrageQueue.append(queuedBarrage)
            return
        }
        
        // 创建新弹幕
        let newBarrage = BarrageItem.create(
            text: text,
            screenSize: screenSize,
            config: config,
            type: type
        )
        
        // 更新最后添加时间
        lastBarrageTime = now
        
        // 添加到活跃弹幕列表
        DispatchQueue.main.async {
            self.activeBarrages.append(newBarrage)
        }
    }
    
    /// 启动动画计时器
    private func startAnimationTimer() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            self.updateBarragePositions()
        }
    }
    
    /// 启动队列处理计时器
    private func startQueueTimer() {
        queueTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, !self.isPaused, !self.barrageQueue.isEmpty else {
                return
            }
            self.processQueue()
        }
    }
    
    /// 处理队列
    private func processQueue() {
        // 检查是否可以添加新弹幕
        let now = Date()
        let timeSinceLastBarrage = now.timeIntervalSince(lastBarrageTime)
        let minInterval = 1.0 / config.density
        
        if timeSinceLastBarrage >= minInterval, let nextBarrage = barrageQueue.first {
            // 移除队列中的第一个弹幕
            barrageQueue.removeFirst()
            
            // 创建并添加弹幕
            createAndAddBarrage(text: nextBarrage.text, type: .normal)
        }
    }
    
    /// 更新弹幕位置
    private func updateBarragePositions() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // 创建新数组以存储更新后的弹幕
            var updatedBarrages: [BarrageItem] = []
            
            for var barrage in self.activeBarrages {
                // 计算移动距离
                let moveDistance = self.config.speed * 3.0
                let effectiveWidth = self.screenSize.width * self.config.travelRange
                
                // 更新位置
                if barrage.direction == .leftToRight {
                    barrage.position.x += moveDistance
                    if barrage.position.x > effectiveWidth {
                        barrage.opacity -= 0.05
                    }
                } else {
                    barrage.position.x -= moveDistance
                    if barrage.position.x < self.screenSize.width - effectiveWidth {
                        barrage.opacity -= 0.05
                    }
                }
                
                // 更新动画状态
                if self.config.enableAnimations {
                    barrage.animationState.update(effect: barrage.style.animationEffect)
                }
                
                // 检查弹幕是否已经超出生命周期
                let age = Date().timeIntervalSince(barrage.createdAt)
                if age > barrage.lifetime {
                    barrage.opacity -= 0.05
                }
                
                // 如果弹幕仍然可见，添加到更新后的数组
                if barrage.opacity > 0 {
                    updatedBarrages.append(barrage)
                }
            }
            
            // 更新活跃弹幕列表
            self.activeBarrages = updatedBarrages
        }
    }
    
    /// 将文本分割成句子
    private func splitTextIntoSentences(_ text: String) -> [String] {
        // 创建一个包含中英文句子结束符的字符集
        let sentenceDelimiters = CharacterSet(charactersIn: "。！？!?.\n")
        
        // 使用句子结束符分割文本
        var sentences: [String] = []
        var currentSentence = ""
        
        for char in text {
            currentSentence.append(char)
            
            // 如果当前字符是句子结束符，添加当前句子到结果中
            if String(char).rangeOfCharacter(from: sentenceDelimiters) != nil {
                if !currentSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                currentSentence = ""
            }
        }
        
        // 添加最后一个句子（如果有）
        if !currentSentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return sentences
    }
    
    // MARK: - 配置持久化
    
    /// 保存配置
    private func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: "BarrageConfig")
        }
    }
    
    /// 加载配置
    private func loadConfig() -> BarrageConfig? {
        if let data = UserDefaults.standard.data(forKey: "BarrageConfig"),
           let config = try? JSONDecoder().decode(BarrageConfig.self, from: data) {
            return config
        }
        return nil
    }
    
    // MARK: - 队列弹幕结构
    
    struct QueuedBarrage {
        let text: String
        let isError: Bool
        let shouldSpeak: Bool
        let completion: (() -> Void)?
    }
}
