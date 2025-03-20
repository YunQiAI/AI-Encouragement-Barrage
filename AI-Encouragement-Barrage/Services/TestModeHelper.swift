//
//  TestModeHelper.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/25.
//

import Foundation
import SwiftData

@MainActor
struct TestModeHelper {
    /// 清空所有历史对话
    static func clearAllConversations(modelContext: ModelContext) async {
        do {
            // 创建获取所有会话的描述符
            let descriptor = FetchDescriptor<Conversation>()
            
            // 获取所有会话
            let conversations = try modelContext.fetch(descriptor)
            
            // 删除所有会话
            for conversation in conversations {
                modelContext.delete(conversation)
            }
            
            // 保存更改
            try modelContext.save()
            
            print("测试模式：已清空所有历史对话，共删除 \(conversations.count) 个会话")
        } catch {
            print("测试模式：清空历史对话失败: \(error.localizedDescription)")
        }
    }
}