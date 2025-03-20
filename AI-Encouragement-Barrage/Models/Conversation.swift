//
//  Conversation.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var messages: [ChatMessage] = []
    
    init(title: String = "新对话", messages: [ChatMessage] = []) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = messages
    }
    
    // 更新最后修改时间
    func updateTimestamp() {
        self.updatedAt = Date()
    }
    
    // 添加消息
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        message.conversation = self
        updateTimestamp()
    }
    
    // 获取最后一条消息（用于预览）
    var lastMessage: ChatMessage? {
        return messages.sorted(by: { $0.timestamp > $1.timestamp }).first
    }
    
    // 获取预览文本
    var previewText: String {
        if let lastMessage = lastMessage {
            let text = lastMessage.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty && lastMessage.imageData != nil {
                return "[图片]"
            } else if text.count > 30 {
                return String(text.prefix(30)) + "..."
            } else {
                return text
            }
        }
        return "无消息"
    }
}