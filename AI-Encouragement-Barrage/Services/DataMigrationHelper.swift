//
//  DataMigrationHelper.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import SwiftData

@MainActor
class DataMigrationHelper {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// 迁移旧版聊天记录到新的会话模型
    func migrateChatsToConversations() async throws {
        // 检查是否已经有会话数据
        let conversationDescriptor = FetchDescriptor<Conversation>()
        let existingConversations = try modelContext.fetch(conversationDescriptor)
        
        // 如果已经有会话数据，不进行迁移
        if !existingConversations.isEmpty {
            print("已存在会话数据，跳过迁移")
            return
        }
        
        // 获取所有现有的聊天消息
        let chatDescriptor = FetchDescriptor<ChatMessage>()
        let existingChats = try modelContext.fetch(chatDescriptor)
        
        // 如果没有聊天记录，创建一个空的默认会话
        if existingChats.isEmpty {
            print("没有聊天记录，创建默认会话")
            let defaultConversation = Conversation(title: "默认对话")
            modelContext.insert(defaultConversation)
            try modelContext.save()
            return
        }
        
        // 创建一个默认会话
        print("开始迁移 \(existingChats.count) 条聊天记录")
        let defaultConversation = Conversation(title: "导入的聊天记录")
        modelContext.insert(defaultConversation)
        
        // 将所有现有聊天消息添加到默认会话中
        for chat in existingChats {
            defaultConversation.addMessage(chat)
        }
        
        // 保存更改
        try modelContext.save()
        print("迁移完成")
    }
}
