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
        NavigationSplitView {
            // 左侧会话列表 - 更窄的设计
            ConversationListView()
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 220)
        } detail: {
            // 右侧会话详情
            if let selectedID = appState.selectedConversationID,
               let selectedConversation = conversations.first(where: { $0.id == selectedID }) {
                ConversationDetailView(
                    aiService: aiService,
                    screenCaptureManager: screenCaptureManager,
                    conversation: selectedConversation
                )
                .frame(minWidth: 500)
            } else {
                ConversationDetailView(
                    aiService: aiService,
                    screenCaptureManager: screenCaptureManager,
                    conversation: nil
                )
                .frame(minWidth: 500)
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
    .frame(width: 900, height: 600) // 设置预览尺寸以更好地展示分割比例
}