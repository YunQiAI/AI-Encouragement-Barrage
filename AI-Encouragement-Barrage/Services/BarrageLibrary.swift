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
    
    // 异步更新的阈值（当70%的弹幕都显示过后触发更新）
    private let updateThreshold: Double = 0.7
    
    // AI服务
    private let aiService: AIService
    
    // 当前上下文
    private var currentContext: String = ""
    
    init(aiService: AIService) {
        self.aiService = aiService
    }
    
    // 设置上下文并初始生成弹幕
    func setContext(_ context: String) async throws {
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
        
        // 检查是否需要异步更新弹幕库
        checkAndUpdateBarrages()
        
        return barrage
    }
    
    // 检查并异步更新弹幕库
    private func checkAndUpdateBarrages() {
        // 计算已显示过的弹幕比例
        let displayedCount = displayCounts.count
        let totalCount = barrages.count
        let displayRatio = Double(displayedCount) / Double(totalCount)
        
        // 如果达到阈值，异步生成新弹幕
        if displayRatio >= updateThreshold {
            Task {
                try? await generateMoreBarrages()
            }
        }
    }
    
    // 异步生成30-50条新弹幕
    private func generateMoreBarrages() async throws {
        // 设置提示词，要求生成30-50条新的不重复的弹幕
        let prompt = """
        基于以下上下文，生成30-50条新的、不重复的、积极鼓励的弹幕消息：
        
        上下文：\(currentContext)
        
        注意：生成的弹幕要有变化，不要重复，要保持积极正面的语气。每条弹幕不超过20个字符，每条弹幕占一行。
        """
        
        let response = try await aiService.analyzeText(text: prompt)
        processAndAddBarrages(response)
        
        // 重置部分显示计数，以便新生成的弹幕有更高的显示机会
        if displayCounts.count > 50 {
            // 保留最近显示次数少的弹幕的计数
            let sortedIds = displayCounts.sorted { $0.value < $1.value }.prefix(20).map { $0.key }
            var newCounts: [UUID: Int] = [:]
            for id in sortedIds {
                newCounts[id] = displayCounts[id]
            }
            displayCounts = newCounts
        }
    }
    
    // 处理AI响应并添加到弹幕库
    private func processAndAddBarrages(_ response: String) {
        // 将响应按行分割，每行作为一条弹幕
        let newBarrages = response
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { text in
                EncouragementMessage(text: text, context: currentContext)
            }
        
        // 添加到弹幕库
        barrages.append(contentsOf: newBarrages)
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
