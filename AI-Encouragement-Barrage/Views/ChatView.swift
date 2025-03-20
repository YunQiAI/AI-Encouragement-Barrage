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
    
    @State private var messageText: String = ""
    @State private var selectedImage: NSImage? = nil
    @State private var isProcessing: Bool = false
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    
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
                    scrollViewProxy = proxy
                    scrollToBottom()
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom()
                }
            }
            
            Divider()
            
            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                // Image selection button
                Button(action: selectImage) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("Add Image")
                
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
        }
    }
    
    private func scrollToBottom() {
        if let lastMessage = messages.last {
            withAnimation {
                scrollViewProxy?.scrollTo(lastMessage.id, anchor: .bottom)
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
        modelContext.insert(userMessage)
        
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
                    aiResponse = try await ollamaService.analyzeImage(image: cgImage)
                } else {
                    // Otherwise use text analysis
                    aiResponse = try await ollamaService.analyzeText(text: trimmedText)
                }
                
                // Create and save AI response message
                DispatchQueue.main.async {
                    let aiMessage = ChatMessage(text: aiResponse, isFromUser: false)
                    self.modelContext.insert(aiMessage)
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
                    self.modelContext.insert(aiMessage)
                    self.isProcessing = false
                }
            }
        }
    }
}

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
    ChatView(ollamaService: AIService(settings: AppSettings()))
        .modelContainer(for: [ChatMessage.self], inMemory: true)
        .environmentObject(AppState())
}