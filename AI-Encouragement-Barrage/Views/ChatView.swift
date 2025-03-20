//
//  ChatView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import SwiftUI
import SwiftData
import AppKit

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var messages: [ChatMessage]
    @EnvironmentObject private var appState: AppState
    @ObservedObject var ollamaService: AIService
    @ObservedObject var screenCaptureManager: ScreenCaptureManager
    
    @State private var messageText: String = ""
    @State private var selectedImage: NSImage? = nil
    @State private var isProcessing: Bool = false
    @State private var countdownWindow: NSWindow? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat history
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
            
            Divider()
            
            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                // Screenshot button
                Button(action: captureAndSendScreenshot) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Capture Screen")
                .disabled(isProcessing)
                
                // Image selection button
                Button(action: selectImage) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Add Image")
                .disabled(isProcessing)
                
                // Image preview (if any)
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
                
                // Text input field
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.textBackgroundColor).opacity(0.1))
                    .cornerRadius(16)
                    .lineLimit(1...5)
                    .disabled(isProcessing)
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage == nil || isProcessing)
                .help("Send Message")
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            // Status area
            HStack {
                Text(isProcessing ? "Processing AI response..." : "Ready")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(Color(.windowBackgroundColor))
        }
        .onAppear {
            startScreenCapture()
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMessage = messages.last {
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func startScreenCapture() {
        screenCaptureManager.startCapturing { image in
            guard let image = image else { return }
            
            isProcessing = true
            
            // 将截屏转换为NSImage
            let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
            
            // 将截屏添加到聊天窗口中
            let imageData = nsImage.tiffRepresentation
            let systemMessage = ChatMessage(text: "自动截屏", isFromUser: true, imageData: imageData)
            
            Task { @MainActor in
                modelContext.insert(systemMessage)
                
                do {
                    let aiResponse = try await ollamaService.analyzeImage(image: image)
                    let aiMessage = ChatMessage(text: aiResponse, isFromUser: false)
                    modelContext.insert(aiMessage)
                    isProcessing = false
                    
                    // Update app state with encouragement
                    appState.updateLastEncouragement(aiResponse)
                } catch {
                    let errorMessage = "AI response failed: \(error.localizedDescription)"
                    let aiMessage = ChatMessage(text: errorMessage, isFromUser: false)
                    modelContext.insert(aiMessage)
                    isProcessing = false
                }
            }
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
                    self.screenCaptureManager.captureScreenNow()
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
        // Ensure there's content to send
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty || selectedImage != nil else { return }
        
        // Prepare image data
        var imageData: Data? = nil
        if let image = selectedImage {
            imageData = image.tiffRepresentation
        }
        
        Task { @MainActor in
            // Create and save user message
            let userMessage = ChatMessage(text: trimmedText, isFromUser: true, imageData: imageData)
            modelContext.insert(userMessage)
            
            // Clear input
            messageText = ""
            selectedImage = nil
            
            // Process AI response
            isProcessing = true
            
            do {
                let aiResponse: String
                
                if let imageData = imageData, let cgImage = NSImage(data: imageData)?.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    // If there's an image, use image analysis
                    aiResponse = try await ollamaService.analyzeImage(image: cgImage)
                } else {
                    // Otherwise use text analysis
                    aiResponse = try await ollamaService.analyzeText(text: trimmedText)
                }
                
                // Create and save AI response message
                let aiMessage = ChatMessage(text: aiResponse, isFromUser: false)
                modelContext.insert(aiMessage)
                isProcessing = false
                
                // If settings allow, show barrage and read aloud
                appState.updateLastEncouragement(aiResponse)
            } catch {
                print("AI response generation failed: \(error)")
                
                // Create error message
                let errorMessage: String
                if let aiError = error as? AIServiceError {
                    errorMessage = "AI response failed: \(aiError.errorDescription ?? "Unknown error")"
                } else {
                    errorMessage = "AI response failed: \(error.localizedDescription)"
                }
                
                let aiMessage = ChatMessage(text: errorMessage, isFromUser: false)
                modelContext.insert(aiMessage)
                isProcessing = false
            }
        }
    }
}



#Preview {
    ChatView(ollamaService: AIService(settings: AppSettings()), screenCaptureManager: ScreenCaptureManager())
        .modelContainer(for: [ChatMessage.self], inMemory: true)
        .environmentObject(AppState())
}
