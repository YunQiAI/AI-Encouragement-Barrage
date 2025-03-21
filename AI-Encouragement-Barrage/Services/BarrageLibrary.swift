//  BarrageLibrary.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import SwiftData

@MainActor
class BarrageLibrary: ObservableObject {
    // 弹幕库
    @Published private var barrages: [EncouragementMessage] = []
    
    // 当前播放的弹幕索引
    private var currentIndex: Int = 0
    
    // AI服务
    private let aiService: AIService
    
    // 当前上下文
    private var currentContext: String = ""
    
    init(aiService: AIService) {
        self.aiService = aiService
    }
    
    // 设置上下文并初始生成弹幕
    func setContext(_ context: String) async throws {
        // 每次设置新上下文时，清空弹幕库
        clearLibrary()
        
        currentContext = context
        try await generateInitialBarrages()
    }
    
    // 初始生成100条弹幕
    private func generateInitialBarrages() async throws {
        let response = try await aiService.analyzeText(text: currentContext)
        processAndAddBarrages(response)
    }
    
    // 按顺序获取下一条弹幕
    func getNextBarrage() -> EncouragementMessage? {
        guard !barrages.isEmpty else { return nil }
        
        // 如果已经到达末尾，重新从头开始
        if currentIndex >= barrages.count {
            currentIndex = 0
        }
        
        // 获取当前索引的弹幕
        let barrage = barrages[currentIndex]
        
        // 索引加1，为下一次获取做准备
        currentIndex += 1
        
        return barrage
    }
    
    // 从弹幕库中随机获取一条弹幕（保留此方法以兼容旧代码）
    func getRandomBarrage() -> EncouragementMessage? {
        return getNextBarrage() // 现在改为按顺序获取
    }
    
    // 处理AI响应并添加到弹幕库
    private func processAndAddBarrages(_ response: String) {
        // 首先，将响应按行分割
        let lines = response.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // 对每一行文本进行句子拆分
        var sentences: [String] = []
        
        for line in lines {
            // 过滤特殊字符
            let filteredLine = filterSpecialCharacters(line)
            
            // 如果过滤后为空，则跳过
            if filteredLine.isEmpty {
                continue
            }
            
            // 将行按句子拆分
            let lineSentences = splitIntoSentences(filteredLine)
            sentences.append(contentsOf: lineSentences)
        }
        
        // 创建弹幕消息
        let newBarrages = sentences
            .filter { !$0.isEmpty }
            .map { EncouragementMessage(text: $0, context: currentContext) }
        
        // 添加到弹幕库
        barrages.append(contentsOf: newBarrages)
    }
    
    // 将文本拆分为句子
    private func splitIntoSentences(_ text: String) -> [String] {
        // 定义句子结束的标点符号
        let sentenceEndingCharacters = CharacterSet(charactersIn: "。！？!?…")
        
        var sentences: [String] = []
        var currentSentence = ""
        
        // 遍历文本的每个字符
        for char in text {
            currentSentence.append(char)
            
            // 如果是句子结束的标点符号，则添加到句子列表中
            if CharacterSet(charactersIn: String(char)).isSubset(of: sentenceEndingCharacters) {
                sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
                currentSentence = ""
            }
        }
        
        // 处理最后一个可能没有结束标点的句子
        if !currentSentence.isEmpty {
            sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return sentences
    }
    
    // 过滤特殊字符和序列
    private func filterSpecialCharacters(_ text: String) -> String {
        // 1. 移除数字序号和前缀（如"1. "、"- "等）
        var filteredText = text.replacingOccurrences(of: "^\\d+\\.\\s*|^-\\s*|^•\\s*", with: "", options: .regularExpression)
        
        // 2. 移除引号
        filteredText = filteredText.replacingOccurrences(of: "[\"']", with: "", options: .regularExpression)
        
        // 3. 移除Markdown标记
        filteredText = filteredText.replacingOccurrences(of: "[*_~`]", with: "", options: .regularExpression)
        
        // 4. 移除表情符号
        let emojiPattern = try! NSRegularExpression(pattern: "[\\p{Emoji}]", options: [])
        filteredText = emojiPattern.stringByReplacingMatches(in: filteredText, options: [], range: NSRange(location: 0, length: filteredText.utf16.count), withTemplate: "")
        
        // 5. 移除控制字符
        filteredText = filteredText.components(separatedBy: CharacterSet.controlCharacters).joined()
        
        // 6. 移除多余的空格
        filteredText = filteredText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return filteredText
    }
    
    // 清除弹幕库
    func clearLibrary() {
        barrages.removeAll()
        currentIndex = 0 // 重置当前索引
    }
    
    // 获取弹幕库大小
    var librarySize: Int {
        barrages.count
    }
}
