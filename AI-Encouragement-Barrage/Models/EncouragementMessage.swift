//
//  EncouragementMessage.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation

/// 鼓励消息模型
struct EncouragementMessage: Identifiable {
    let id: UUID
    let text: String
    let context: String?
    let timestamp: Date
    
    init(text: String, context: String? = nil) {
        self.id = UUID()
        self.text = text
        self.context = context
        self.timestamp = Date()
    }
}
