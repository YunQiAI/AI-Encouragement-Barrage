//
//  ConversationListView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]
    @EnvironmentObject private var appState: AppState
    
    @State private var showingNewConversationAlert = false
    @State private var newConversationTitle = "新对话"
    @State private var editingConversation: Conversation? = nil
    @State private var editingTitle = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题和新建按钮
            HStack {
                Text("对话")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    newConversationTitle = "新对话"
                    showingNewConversationAlert = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .padding(.trailing)
                .help("新建对话")
            }
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // 会话列表
            if conversations.isEmpty {
                VStack {
                    Spacer()
                    Text("没有对话")
                        .foregroundColor(.secondary)
                    Text("点击右上角按钮新建对话")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    Spacer()
                }
            } else {
                List(selection: Binding(
                    get: { appState.selectedConversationID },
                    set: { appState.selectConversation($0) }
                )) {
                    ForEach(conversations) { conversation in
                        ConversationRow(conversation: conversation)
                            .id(conversation.id)
                            .contextMenu {
                                Button(action: {
                                    editingConversation = conversation
                                    editingTitle = conversation.title
                                }) {
                                    Label("重命名", systemImage: "pencil")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive, action: {
                                    deleteConversation(conversation)
                                }) {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .frame(minWidth: 200)
        .alert("新建对话", isPresented: $showingNewConversationAlert) {
            TextField("对话标题", text: $newConversationTitle)
            
            Button("取消", role: .cancel) {}
            Button("创建") {
                createNewConversation()
            }
        } message: {
            Text("请输入新对话的标题")
        }
        .alert("重命名对话", isPresented: Binding(
            get: { editingConversation != nil },
            set: { if !$0 { editingConversation = nil } }
        )) {
            TextField("对话标题", text: $editingTitle)
            
            Button("取消", role: .cancel) {
                editingConversation = nil
            }
            Button("重命名") {
                if let conversation = editingConversation {
                    conversation.title = editingTitle
                    conversation.updateTimestamp()
                }
                editingConversation = nil
            }
        } message: {
            Text("请输入新的对话标题")
        }
        .onAppear {
            // 如果没有选中的会话但有会话列表，选择第一个
            if appState.selectedConversationID == nil && !conversations.isEmpty {
                appState.selectConversation(conversations.first?.id)
            }
            
            // 如果没有会话，创建一个默认会话
            if conversations.isEmpty {
                createDefaultConversation()
            }
        }
    }
    
    private func createNewConversation() {
        let conversation = Conversation(title: newConversationTitle)
        modelContext.insert(conversation)
        appState.selectConversation(conversation.id)
    }
    
    private func createDefaultConversation() {
        let conversation = Conversation(title: "默认对话")
        modelContext.insert(conversation)
        appState.selectConversation(conversation.id)
    }
    
    private func deleteConversation(_ conversation: Conversation) {
        // 如果删除的是当前选中的会话，选择另一个会话
        if conversation.id == appState.selectedConversationID {
            let remainingConversations = conversations.filter { $0.id != conversation.id }
            appState.selectConversation(remainingConversations.first?.id)
        }
        
        modelContext.delete(conversation)
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Text(conversation.previewText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(conversation.updatedAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConversationListView()
        .modelContainer(for: [Conversation.self, ChatMessage.self], inMemory: true)
        .environmentObject(AppState())
}