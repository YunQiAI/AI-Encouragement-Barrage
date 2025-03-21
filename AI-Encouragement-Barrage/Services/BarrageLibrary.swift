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
    
    // 用于追踪每条弹幕的显示次数
    private var displayCounts: [UUID: Int] = [:]
    
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
    
    // 从弹幕库中随机获取一条弹幕
    func getRandomBarrage() -> EncouragementMessage? {
        guard !barrages.isEmpty else { return nil }
        
        let index = Int.random(in: 0..<barrages.count)
        let barrage = barrages[index]
        
        // 更新显示次数
        let currentCount = displayCounts[barrage.id] ?? 0
        displayCounts[barrage.id] = currentCount + 1
        
        return barrage
    }
    
    // 处理AI响应并添加到弹幕库
    private func processAndAddBarrages(_ response: String) {
        // 将响应按行分割，每行作为一条弹幕
        let newBarrages = response
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { text in
                // 过滤特殊字符和序列
                let filteredText = filterSpecialCharacters(text)
                return EncouragementMessage(text: filteredText, context: currentContext)
            }
            .filter { !$0.text.isEmpty } // 过滤掉空文本
        
        // 添加到弹幕库
        barrages.append(contentsOf: newBarrages)
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
        displayCounts.removeAll()
    }
    
    // 获取弹幕库大小
    var librarySize: Int {
        barrages.count
    }
}
