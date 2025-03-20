//
//  MessageBubble.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import SwiftUI
import AppKit

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 6) {
                // If there's an image, display it
                if let imageData = message.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 200)
                        .cornerRadius(8)
                }
                
                // If there's text, display it
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(10)
                        .background(message.isFromUser ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(message.isFromUser ? .white : .primary)
                        .cornerRadius(16)
                }
                
                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isFromUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack {
        MessageBubble(
            message: ChatMessage(
                text: "Hello! This is a test message.",
                isFromUser: true
            )
        )
        
        MessageBubble(
            message: ChatMessage(
                text: "This is a response message.",
                isFromUser: false
            )
        )
    }
    .frame(width: 300)
}
