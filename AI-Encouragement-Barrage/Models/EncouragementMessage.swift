//
//  EncouragementMessage.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import SwiftData

@Model
final class EncouragementMessage {
    var id: UUID
    var text: String
    var timestamp: Date
    var context: String?  // 可选，记录生成这条消息时的上下文
    
    init(text: String, context: String? = nil) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.context = context
    }
}