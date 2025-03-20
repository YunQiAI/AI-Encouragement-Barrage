//
//  ConversationDetailView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import SwiftUI
import SwiftData
import AppKit

struct ConversationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @ObservedObject var aiService: AIService
    @ObservedObject var screenCaptureManager: ScreenCaptureManager
    
    @State private var messageText: String = ""
    @State private var selectedImage: NSImage? = nil
    @State private var isProcessing: Bool = false
    @State private var countdownWindow: NSWindow? = nil
    @State private var isEditingTitle: Bool = false
    @State private var editingTitle: String = ""
    
    var conversation: Conversation
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                if isEditingTitle {
                    TextField("对话标题", text: $editingTitle, onCommit: {
                        conversation.title = editingTitle
                        conversation.updateTimestamp()
                        isEditingTitle = false
                    })
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color(.textBackgroundColor).opacity(0.1))
                    .cornerRadius(4)
                    .padding(.leading)
                    .onExitCommand {
                        isEditingTitle = false
                    }
                } else {
                    Text(conversation.title)
                        .font(.headline)
                        .padding(.leading)
                        .onTapGesture(count: 2) {
                            editingTitle = conversation.title
                            isEditingTitle = true
                        }
                }
                
                Spacer()
                
                // 屏幕监控开关
                Toggle(isOn: $appState.isScreenAnalysisActive) {
                    Text("监控")
                        .font(.subheadline)
                }
                .toggleStyle(.switch)
                .padding(.trailing)
                .help(appState.isScreenAnalysisActive ? "关闭屏幕监控" : "开启屏幕监控")
                
                // 弹幕开关
                Toggle(isOn: $appState.isRunning) {
                    Text("弹幕")
                        .font(.subheadline)
                }
                .toggleStyle(.switch)
                .padding(.trailing)
                .help(appState.isRunning ? "关闭弹幕" : "开启弹幕")
            }
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // 聊天历史
            ChatHistoryView(conversation: conversation)
            
            Divider()
            
            // 输入区域
            HStack(alignment: .bottom, spacing: 8) {
                // 截图按钮
                Button(action: captureAndSendScreenshot) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("截取屏幕")
                .disabled(isProcessing)
                
                // 图片选择按钮
                Button(action: selectImage) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("添加图片")
                .disabled(isProcessing)
                
                // 图片预览（如果有）
                if let selectedImage = selectedImage {
                    ZStack(alignment: .topTrailing) {
                        Image(nsImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .cornerRadius(8)
                        
                        Button(action: { self.selectedImage = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .buttonStyle(.plain)
                        .padding(2)
                    }
                }
                
                // 文本输入框
                TextField("输入消息...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.textBackgroundColor).opacity(0.1))
                    .cornerRadius(16)
                    .lineLimit(1...5)
                    .disabled(isProcessing)
                
                // 发送按钮
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage == nil || isProcessing)
                .help("发送消息")
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            // 状态区域
            HStack {
                Text(isProcessing ? "AI正在处理..." : "就绪")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(Color(.windowBackgroundColor))
        }
        .onChange(of: appState.selectedConversationID) { _, _ in
            // 清除输入状态
            messageText = ""
            selectedImage = nil
            isProcessing = false
        }
        .onAppear {
            // 确保ScreenCaptureManager知道当前会话
            appState.selectConversation(conversation.id)
            
            // 加载保存的设置
            appState.loadSavedSettings()
            
            // 设置通知监听器
            setupNotificationObservers()
        }
        .onDisappear {
            // 移除通知监听器
            removeNotificationObservers()
        }
    }
}

// MARK: - Private Methods
extension ConversationDetailView {
    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let image = NSImage(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.selectedImage = image
                    }
                }
            }
        }
    }
    
    private func captureAndSendScreenshot() {
        isProcessing = true
        
        // 创建一个倒计时窗口，让用户有时间准备
        let countdown = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        countdown.title = "截屏倒计时"
        countdown.center()
        
        // 保存窗口引用，防止提前释放
        self.countdownWindow = countdown
        
        // 创建倒计时视图
        let countdownView = CountdownView {
            // 关闭窗口
            DispatchQueue.main.async {
                self.countdownWindow?.close()
                self.countdownWindow = nil
                
                // 延迟一小段时间，确保倒计时窗口已关闭
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 捕获屏幕，并获取当前会话ID
                    self.screenCaptureManager.captureScreenNow { image, capturedConversationID in
                        guard let image = image else {
                            self.isProcessing = false
                            return
                        }
                        
                        // 确定使用哪个会话ID
                        let targetConversationID = capturedConversationID ?? conversation.id
                        
                        // 查找对应的会话
                        let targetConversation = self.findConversation(with: targetConversationID) ?? conversation
                        
                        // 将截屏转换为NSImage
                        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
                        
                        // 将截屏添加到聊天窗口中
                        let imageData = nsImage.tiffRepresentation
                        let userMessage = ChatMessage(text: "自动截屏", isFromUser: true, imageData: imageData)
                        userMessage.conversationID = targetConversation.id
                        targetConversation.addMessage(userMessage)
                        
                        print("截图已添加到会话: \(targetConversation.title), ID: \(targetConversation.id)")
                        
                        Task {
                            do {
                                let aiResponse = try await aiService.analyzeImage(image: image)
                                
                                DispatchQueue.main.async {
                                    let aiMessage = ChatMessage(text: aiResponse, isFromUser: false)
                                    aiMessage.conversationID = targetConversation.id
                                    targetConversation.addMessage(aiMessage)
                                    self.isProcessing = false
                                    
                                    // Update app state with encouragement
                                    self.appState.updateLastEncouragement(aiResponse)
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    let errorMessage = "AI response failed: \(error.localizedDescription)"
                                    let aiMessage = ChatMessage(text: errorMessage, isFromUser: false)
                                    aiMessage.conversationID = targetConversation.id
                                    targetConversation.addMessage(aiMessage)
                                    self.isProcessing = false
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 设置窗口内容
        let hostingView = NSHostingView(rootView: countdownView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 100)
        countdown.contentView = hostingView
        
        // 显示窗口
        countdown.makeKeyAndOrderFront(nil)
    }
    
    private func setupNotificationObservers() {
        // 监听截图通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ScreenCaptureReceived"),
            object: nil,
            queue: .main
        ) { notification in
            handleScreenCaptureNotification(notification)
        }
        
        // 监听AI回复通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AIResponseReceived"),
            object: nil,
            queue: .main
        ) { notification in
            handleAIResponseNotification(notification)
        }
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ScreenCaptureReceived"),
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("AIResponseReceived"),
            object: nil
        )
    }
    
    private func handleScreenCaptureNotification(_ notification: Notification) {
        print("【日志19】ConversationDetailView收到截图通知")
        
        guard let userInfo = notification.userInfo,
              let conversationID = userInfo["conversationID"] as? UUID,
              let imageData = userInfo["imageData"] as? Data else {
            print("【错误】截图通知缺少必要信息")
            if let userInfo = notification.userInfo {
                print("【错误】userInfo内容: \(userInfo)")
            }
            return
        }
        
        print("【日志20】截图通知包含会话ID: \(conversationID)")
        print("【日志21】当前会话ID: \(conversation.id.uuidString)")
        
        // 检查是否是当前会话
        if conversation.id == conversationID {
            print("【日志22】会话ID匹配，添加截图到当前会话")
            
            // 创建用户消息并添加到会话
            let userMessage = ChatMessage(text: "自动屏幕分析", isFromUser: true, imageData: imageData)
            userMessage.conversationID = conversationID
            conversation.addMessage(userMessage)
            
            print("【日志23】已将截图添加到当前会话")
        } else {
            print("【错误】会话ID不匹配，无法添加截图")
        }
    }
    
    private func handleAIResponseNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let conversationID = userInfo["conversationID"] as? UUID,
              let response = userInfo["response"] as? String else {
            print("AI回复通知缺少必要信息")
            return
        }
        
        // 检查是否是当前会话
        if conversation.id == conversationID {
            // 创建AI回复消息并添加到会话
            let aiMessage = ChatMessage(text: response, isFromUser: false)
            aiMessage.conversationID = conversationID
            conversation.addMessage(aiMessage)
            
            print("已将AI回复添加到当前会话")
        }
    }
    
    private func findConversation(with id: UUID) -> Conversation? {
        // 如果当前会话ID匹配，直接返回
        if conversation.id == id {
            return conversation
        }
        
        // 否则使用modelContext查询
        do {
            let descriptor = FetchDescriptor<Conversation>(
                predicate: #Predicate<Conversation> { $0.id == id }
            )
            let conversations = try modelContext.fetch(descriptor)
            return conversations.first
        } catch {
            print("查找会话失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func sendMessage() {
        // Ensure there's content to send
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty || selectedImage != nil else { return }
        
        // Prepare image data
        var imageData: Data? = nil
        if let image = selectedImage {
            imageData = image.tiffRepresentation
        }
        
        // Create and save user message
        let userMessage = ChatMessage(text: trimmedText, isFromUser: true, imageData: imageData)
        userMessage.conversationID = conversation.id
        conversation.addMessage(userMessage)
        
        // Clear input
        messageText = ""
        selectedImage = nil
        
        // Process AI response
        isProcessing = true
        
        Task {
            do {
                var aiResponse: String
                
                if let imageData = imageData, let cgImage = NSImage(data: imageData)?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    // If there's an image, use image analysis
                    aiResponse = try await aiService.analyzeImage(image: cgImage)
                } else {
                    // Otherwise use text analysis
                    aiResponse = try await aiService.analyzeText(text: trimmedText)
                }
                
                // Create and save AI response message
                DispatchQueue.main.async {
                    let aiMessage = ChatMessage(text: aiResponse, isFromUser: false)
                    aiMessage.conversationID = conversation.id
                    conversation.addMessage(aiMessage)
                    self.isProcessing = false
                    
                    // If settings allow, show barrage and read aloud
                    self.appState.updateLastEncouragement(aiResponse)
                }
            } catch {
                print("AI response generation failed: \(error)")
                
                // Create error message
                DispatchQueue.main.async {
                    let errorMessage: String
                    if let aiError = error as? AIServiceError {
                        errorMessage = "AI response failed: \(aiError.errorDescription ?? "Unknown error")"
                    } else {
                        errorMessage = "AI response failed: \(error.localizedDescription)"
                    }
                    
                    let aiMessage = ChatMessage(text: errorMessage, isFromUser: false)
                    aiMessage.conversationID = conversation.id
                    conversation.addMessage(aiMessage)
                    self.isProcessing = false
                }
            }
        }
    }
}

// MARK: - ChatHistoryView
struct ChatHistoryView: View {
    @Query var messages: [ChatMessage]
    
    init(conversation: Conversation) {
        let conversationID = conversation.id
        self._messages = Query(filter: #Predicate {
            $0.conversationID == conversationID || $0.conversation?.id == conversationID
        }, sort: \.timestamp)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .background(Color(.textBackgroundColor).opacity(0.05))
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - CountdownView

#Preview {
    ConversationDetailView(
        aiService: AIService(settings: AppSettings()),
        screenCaptureManager: ScreenCaptureManager(),
        conversation: Conversation(title: "测试对话")
    )
    .modelContainer(for: [Conversation.self, ChatMessage.self], inMemory: true)
    .environmentObject(AppState())
}
