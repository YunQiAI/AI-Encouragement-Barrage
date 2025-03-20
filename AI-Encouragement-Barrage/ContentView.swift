//
//  ContentView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]
    @EnvironmentObject private var appState: AppState
    
    // Service components
    @State private var screenCaptureManager: ScreenCaptureManager?
    @State private var aiService: AIService?
    @State private var barrageOverlayWindow: BarrageOverlayWindow?
    @State private var speechSynthesizer: SpeechSynthesizer?
    @State private var statusBarController: StatusBarController?
    
    // UI state
    @State private var selectedTab = 0
    @State private var testVoiceText: String = "我们很棒，不是吗？"
    @State private var showTestVoicePopup: Bool = false
    @State private var currentSettings: AppSettings = AppSettings()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat interface
            if let aiService = aiService {
                ChatView(ollamaService: aiService)
                    .tabItem {
                        Label("Chat", systemImage: "bubble.left.and.bubble.right")
                    }
                    .tag(0)
            }
            
            // Settings interface
            SettingsView(
                testVoiceText: $testVoiceText,
                showTestVoicePopup: $showTestVoicePopup
            )
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(1)
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            initializeServices()
            setupStatusBar()
            setupNotificationObservers()
        }
        .onChange(of: appState.isRunning) { _, isRunning in
            if isRunning {
                startServices()
            } else {
                stopServices()
            }
        }
        .onChange(of: appState.shouldTestBarrages) { _, shouldTest in
            if shouldTest {
                sendTestBarrages()
            }
        }
        .onChange(of: appSettings) { _, _ in
            // Update service configuration when settings change
            updateServicesConfig()
        }
        .sheet(isPresented: $showTestVoicePopup) {
            if let settings = appSettings.first {
                TestVoiceView(
                    testVoiceText: $testVoiceText,
                    showTestVoicePopup: $showTestVoicePopup,
                    settings: .constant(settings)
                )
            } else {
                TestVoiceView(
                    testVoiceText: $testVoiceText,
                    showTestVoicePopup: $showTestVoicePopup,
                    settings: .constant(AppSettings())
                )
            }
        }
    }
    
    // Initialize all services
    private func initializeServices() {
        // Load settings
        let settings = appSettings.first ?? AppSettings()
        currentSettings = settings
        
        // Initialize service components
        screenCaptureManager = ScreenCaptureManager(captureInterval: settings.captureInterval)
        aiService = AIService(settings: settings)
        barrageOverlayWindow = BarrageOverlayWindow()
        speechSynthesizer = SpeechSynthesizer()
        
        // Set custom voice if specified
        if let voiceIdentifier = settings.voiceIdentifier {
            speechSynthesizer?.setVoice(identifier: voiceIdentifier)
        }
        
        // Set barrage speed and direction
        barrageOverlayWindow?.setSpeed(settings.barrageSpeed)
        if let direction = settings.barrageDirection {
            barrageOverlayWindow?.setDirection(direction)
        }
        if let range = settings.barrageTravelRange {
            barrageOverlayWindow?.setTravelRange(range)
        }
        
        // Check screen capture permission
        if let screenCaptureManager = screenCaptureManager {
            if !screenCaptureManager.checkScreenCapturePermission() {
                screenCaptureManager.requestScreenCapturePermission()
            }
        }
    }
    
    // Set up notification observers
    private func setupNotificationObservers() {
        // Listen for temporary settings changes from SettingsView
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TemporarySettingsChanged"),
            object: nil,
            queue: .main
        ) { notification in
            if let settings = notification.userInfo?["settings"] as? AppSettings {
                self.applyTemporarySettings(settings)
            }
        }
    }
    
    // Apply temporary settings without saving to database
    private func applyTemporarySettings(_ settings: AppSettings) {
        // Update current settings
        currentSettings = settings
        
        // Update screen capture interval
        screenCaptureManager?.setCaptureInterval(settings.captureInterval)
        
        // Update AI service configuration
        aiService?.updateConfig(settings: settings)
        
        // Set custom voice if specified
        if let voiceIdentifier = settings.voiceIdentifier {
            speechSynthesizer?.setVoice(identifier: voiceIdentifier)
        }
        
        // Update barrage settings
        barrageOverlayWindow?.setSpeed(settings.barrageSpeed)
        if let direction = settings.barrageDirection {
            barrageOverlayWindow?.setDirection(direction)
        }
        if let range = settings.barrageTravelRange {
            barrageOverlayWindow?.setTravelRange(range)
        }
    }
    
    // Update service configuration
    private func updateServicesConfig() {
        guard let settings = appSettings.first else { return }
        currentSettings = settings
        
        // Update screen capture interval
        screenCaptureManager?.setCaptureInterval(settings.captureInterval)
        
        // Update AI service configuration
        aiService?.updateConfig(settings: settings)
        
        // Set custom voice if specified
        if let voiceIdentifier = settings.voiceIdentifier {
            speechSynthesizer?.setVoice(identifier: voiceIdentifier)
        }
        
        // Update barrage settings
        barrageOverlayWindow?.setSpeed(settings.barrageSpeed)
        if let direction = settings.barrageDirection {
            barrageOverlayWindow?.setDirection(direction)
        }
        if let range = settings.barrageTravelRange {
            barrageOverlayWindow?.setTravelRange(range)
        }
    }
    
    // Set up status bar
    private func setupStatusBar() {
        DispatchQueue.main.async {
            // Create status bar controller with just the app state
            self.statusBarController = StatusBarController(appState: self.appState)
        }
    }
    
    // Start services
    private func startServices() {
        // Show barrage window
        barrageOverlayWindow?.show()
        
        // Start screen capture
        screenCaptureManager?.startCapturing { image in
            guard let image = image else { return }
            
            // Update state
            self.appState.setProcessing(true)
            
            // Analyze screenshot
            Task {
                do {
                    if let aiService = self.aiService {
                        let encouragement = try await aiService.analyzeImage(image: image)
                        
                        // Update state
                        self.appState.updateLastEncouragement(encouragement)
                        
                        // Show barrage
                        self.barrageOverlayWindow?.addBarrage(text: encouragement)
                        
                        // Save to database
                        let message = EncouragementMessage(text: encouragement)
                        self.modelContext.insert(message)
                        
                        // If speech is enabled, read the encouragement
                        if let settings = self.appSettings.first, settings.speechEnabled {
                            self.speechSynthesizer?.speak(text: encouragement)
                        }
                    }
                } catch {
                    print("Failed to analyze screenshot: \(error)")
                    
                    // Show error message as barrage
                    if let aiError = error as? AIServiceError {
                        self.barrageOverlayWindow?.addBarrage(text: "AI analysis failed: \(aiError.errorDescription ?? "Unknown error")", isError: true)
                    } else {
                        self.barrageOverlayWindow?.addBarrage(text: "AI analysis failed: \(error.localizedDescription)", isError: true)
                    }
                }
                
                // Update state
                self.appState.setProcessing(false)
            }
        }
    }
    
    // Stop services
    private func stopServices() {
        // Stop screen capture
        screenCaptureManager?.stopCapturing()
        
        // Stop speech
        speechSynthesizer?.stop()
        
        // Clear barrages
        barrageOverlayWindow?.clearAllBarrages()
        
        // Hide barrage window
        barrageOverlayWindow?.hide()
    }
    
    // Breaking up the complex expression into simpler parts to fix compiler error
    private func sendTestBarrages() {
        barrageOverlayWindow?.show()
        
        // Define test messages in Chinese
        let testBarrages1 = [
            "你的代码看起来很优雅！继续加油！",
            "你是解决问题的高手！"
        ]
        
        let testBarrages2 = [
            "这个设计非常出色，继续努力！",
            "看到你的进步真是鼓舞人心！"
        ]
        
        let testBarrages3 = [
            "你的创造性思维令人印象深刻！",
            "这个实现非常优雅！"
        ]
        
        let testBarrages4 = [
            "困难只是暂时的，你一定能克服！",
            "你的专注力令人钦佩！"
        ]
        
        let testBarrages5 = [
            "你处理复杂问题的方式非常出色！",
            "坚持就会成功，你做得很棒！"
        ]
        
        // Combine all test messages
        let allTestBarrages = testBarrages1 + testBarrages2 + testBarrages3 + testBarrages4 + testBarrages5
        
        // Display and speak messages one by one, synchronized
        displayNextBarrage(messages: allTestBarrages, index: 0)
    }
    
    // Helper method to display barrages one by one, synchronized with speech
    private func displayNextBarrage(messages: [String], index: Int) {
        // Check if we've reached the end of the messages
        if index >= messages.count {
            return
        }
        
        // Get the current message
        let text = messages[index]
        
        // Show the barrage
        self.barrageOverlayWindow?.addBarrage(text: text)
        
        // If speech is enabled, read the message and wait for completion before showing next
        if let settings = self.appSettings.first, settings.speechEnabled, let speechSynthesizer = self.speechSynthesizer {
            speechSynthesizer.speak(text: text) {
                // When speech is complete, display the next barrage after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.displayNextBarrage(messages: messages, index: index + 1)
                }
            }
        } else {
            // If speech is not enabled, display the next barrage after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.displayNextBarrage(messages: messages, index: index + 1)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [AppSettings.self, EncouragementMessage.self, ChatMessage.self], inMemory: true)
        .environmentObject(AppState())
}
