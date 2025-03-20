//
//  ChatMessage.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class ChatMessage {
    var id: UUID
    var text: String
    var isFromUser: Bool
    var timestamp: Date
    var conversationID: UUID?
    var imageData: Data?
    
    // 新增与Conversation的关系
    @Relationship(inverse: \Conversation.messages) var conversation: Conversation?
    
    init(text: String, isFromUser: Bool, imageData: Data? = nil) {
        self.id = UUID()
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.imageData = imageData
    }
}