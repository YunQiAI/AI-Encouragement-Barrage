//
//  BarrageManager.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import SwiftUI
import AppKit

// 旧版弹幕管理器 - 为了向后兼容保留
// 新代码应该使用 BarrageEngine 和 BarrageService
class BarrageManager: ObservableObject {
    @Published var activeBarrages: [BarrageItem] = []
    private var speed: Double = 1.0
    private var timer: Timer?
    var screenSize: CGSize
    private var directionSetting: String = "rightToLeft" // Default right to left
    private var travelRange: Double = 1.0 // Default full screen
    
    init(screenSize: CGSize) {
        self.screenSize = screenSize
        startAnimationTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // 添加弹幕
    func addBarrage(text: String, isError: Bool = false) {
        // 创建配置
        var config = BarrageConfig()
        config.speed = speed
        config.travelRange = travelRange
        
        // 设置方向
        switch directionSetting {
        case "leftToRight":
            config.direction = .leftToRight
        case "rightToLeft":
            config.direction = .rightToLeft
        case "bidirectional":
            config.direction = .bidirectional
        default:
            config.direction = .rightToLeft
        }
        
        // 创建弹幕
        let newBarrage = BarrageItem.create(
            text: text,
            screenSize: screenSize,
            config: config,
            type: isError ? BarrageItem.BarrageType.error : BarrageItem.BarrageType.normal
        )
        
        DispatchQueue.main.async {
            self.activeBarrages.append(newBarrage)
            
            // 更新弹幕存活时间，根据速度和屏幕宽度计算
            let travelTime = (self.screenSize.width + 400) / (self.speed * 3.0) * 0.03
            DispatchQueue.main.asyncAfter(deadline: .now() + travelTime) {
                self.activeBarrages.removeAll { $0.id == newBarrage.id }
            }
        }
    }
    
    // 清除所有弹幕
    func clearAllBarrages() {
        activeBarrages.removeAll()
    }
    
    // 设置弹幕速度
    func setSpeed(_ speed: Double) {
        self.speed = speed
    }
    
    // 设置弹幕方向
    func setDirection(_ direction: String) {
        self.directionSetting = direction
    }
    
    // 设置弹幕显示范围
    func setTravelRange(_ range: Double) {
        self.travelRange = range
    }
    
    // 更新屏幕大小
    func updateScreenSize(_ size: CGSize) {
        self.screenSize = size
    }
    
    // 添加多条弹幕，用于处理长文本
    func addMultipleBarrages(text: String, isError: Bool = false) {
        // 将文本按句子分割
        let sentences = splitTextIntoSentences(text)
        
        // 为每个句子创建一个弹幕
        for sentence in sentences {
            addBarrage(text: sentence, isError: isError)
        }
    }
    
    // 将文本分割成句子
    func splitTextIntoSentences(_ text: String) -> [String] {
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
    
    // 处理流式响应
    func processStreamingResponse(_ partial: String) {
        // 分割文本
        let sentences = splitTextIntoSentences(partial)
        
        // 只处理非空句子
        for sentence in sentences where !sentence.isEmpty {
            addBarrage(text: sentence)
        }
    }
    
    private func startAnimationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateBarragePositions()
        }
    }
    
    private func updateBarragePositions() {
        DispatchQueue.main.async {
            for i in 0..<self.activeBarrages.count {
                var barrage = self.activeBarrages[i]
                let moveDistance = self.speed * 3.0
                let effectiveWidth = self.screenSize.width * self.travelRange
                
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
                
                self.activeBarrages[i] = barrage
            }
            
            self.activeBarrages.removeAll { $0.opacity <= 0 }
        }
    }
}