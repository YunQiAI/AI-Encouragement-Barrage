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
    
    var conversation: Conversation?
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                if isEditingTitle {
                    TextField("对话标题", text: $editingTitle, onCommit: {
                        if let conversation = conversation {
                            conversation.title = editingTitle
                            conversation.updateTimestamp()
                        }
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
                    Text(conversation?.title ?? "无对话")
                        .font(.headline)
                        .padding(.leading)
                        .onTapGesture(count: 2) {
                            if let conversation = conversation {
                                editingTitle = conversation.title
                                isEditingTitle = true
                            }
                        }
                }
                
                Spacer()
                
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
            
            if conversation == nil {
                // 无选中会话时的提示
                VStack {
                    Spacer()
                    Text("请选择或创建一个对话")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                // 聊天历史
                ChatHistoryView(conversation: conversation!)
                
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
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage == nil || isProcessing || conversation == nil)
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
        }
        .onChange(of: appState.selectedConversationID) { _, _ in
            // 清除输入状态
            messageText = ""
            selectedImage = nil
            isProcessing = false
        }
    }
    
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
        guard let conversation = conversation else { return }
        
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
                    // 捕获屏幕
                    self.screenCaptureManager.captureScreenNow { image in
                        guard let image = image else {
                            self.isProcessing = false
                            return
                        }
                        
                        // 将截屏转换为NSImage
                        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
                        
                        // 将截屏添加到聊天窗口中
                        let imageData = nsImage.tiffRepresentation
                        let userMessage = ChatMessage(text: "自动截屏", isFromUser: true, imageData: imageData)
                        conversation.addMessage(userMessage)
                        
                        Task {
                            do {
                                let aiResponse = try await aiService.analyzeImage(image: image)
                                
                                DispatchQueue.main.async {
                                    let aiMessage = ChatMessage(text: aiResponse, isFromUser: false)
                                    conversation.addMessage(aiMessage)
                                    self.isProcessing = false
                                    
                                    // Update app state with encouragement
                                    self.appState.updateLastEncouragement(aiResponse)
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    let errorMessage = "AI response failed: \(error.localizedDescription)"
                                    let aiMessage = ChatMessage(text: errorMessage, isFromUser: false)
                                    conversation.addMessage(aiMessage)
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
    
    private func sendMessage() {
        guard let conversation = conversation else { return }
        
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
                    conversation.addMessage(aiMessage)
                    self.isProcessing = false
                }
            }
        }
    }
}

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

#Preview {
    ConversationDetailView(
        aiService: AIService(settings: AppSettings()),
        screenCaptureManager: ScreenCaptureManager(),
        conversation: Conversation(title: "测试对话")
    )
    .modelContainer(for: [Conversation.self, ChatMessage.self], inMemory: true)
    .environmentObject(AppState())
}