//
//  ChatInterfaceView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import SwiftUI
import SwiftData

struct ChatInterfaceView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query private var conversations: [Conversation]
    
    @ObservedObject var aiService: AIService
    @ObservedObject var screenCaptureManager: ScreenCaptureManager
    
    var body: some View {
        HSplitView {
            // 左侧会话列表
            ConversationListView()
                .frame(minWidth: 200)
            
            // 右侧会话详情
            if let selectedID = appState.selectedConversationID,
               let selectedConversation = conversations.first(where: { $0.id == selectedID }) {
                ConversationDetailView(
                    aiService: aiService,
                    screenCaptureManager: screenCaptureManager,
                    conversation: selectedConversation
                )
            } else {
                ConversationDetailView(
                    aiService: aiService,
                    screenCaptureManager: screenCaptureManager,
                    conversation: nil
                )
            }
        }
        .onAppear {
            // 如果没有选中的会话但有会话列表，选择第一个
            if appState.selectedConversationID == nil && !conversations.isEmpty {
                appState.selectConversation(conversations.first?.id)
            }
        }
    }
}

#Preview {
    ChatInterfaceView(
        aiService: AIService(settings: AppSettings()),
        screenCaptureManager: ScreenCaptureManager()
    )
    .modelContainer(for: [Conversation.self, ChatMessage.self], inMemory: true)
    .environmentObject(AppState())
}