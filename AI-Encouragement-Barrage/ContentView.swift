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
    @State private var barrageQueue: BarrageQueue?
    
    // UI state
    @State private var selectedTab = 0
    @State private var testVoiceText: String = "我们很棒，不是吗？"
    @State private var showTestVoicePopup: Bool = false
    @State private var currentSettings: AppSettings = AppSettings()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat interface
            if let aiService = aiService, let screenCaptureManager = screenCaptureManager {
                ChatView(ollamaService: aiService, screenCaptureManager: screenCaptureManager)
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
        let settings = appSettings.first ?? AppSettings()
        currentSettings = settings
        
        barrageOverlayWindow = BarrageOverlayWindow()
        speechSynthesizer = SpeechSynthesizer()
        
        if let barrageOverlayWindow = barrageOverlayWindow,
           let speechSynthesizer = speechSynthesizer {
            // Initialize barrage queue
            barrageQueue = BarrageQueue(
                barrageWindow: barrageOverlayWindow,
                speechSynthesizer: speechSynthesizer
            )
            barrageQueue?.setSpeechEnabled(settings.speechEnabled)
            
            // Initialize other services
            screenCaptureManager = ScreenCaptureManager(captureInterval: settings.captureInterval)
            aiService = AIService(settings: settings, barrageManager: barrageOverlayWindow.barrageManager)
            
            // Set custom voice if specified
            if let voiceIdentifier = settings.voiceIdentifier {
                speechSynthesizer.setVoice(identifier: voiceIdentifier)
            }
            
            // Set barrage speed and direction
            barrageOverlayWindow.setSpeed(settings.barrageSpeed)
            if let direction = settings.barrageDirection {
                barrageOverlayWindow.setDirection(direction)
            }
            if let range = settings.barrageTravelRange {
                barrageOverlayWindow.setTravelRange(range)
            }
            
            // Check screen capture permission
            if let screenCaptureManager = screenCaptureManager {
                if !screenCaptureManager.checkScreenCapturePermission() {
                    screenCaptureManager.requestScreenCapturePermission()
                }
            }
        }
    }
    
    private func setupNotificationObservers() {
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
    
    private func applyTemporarySettings(_ settings: AppSettings) {
        currentSettings = settings
        barrageQueue?.setSpeechEnabled(settings.speechEnabled)
        updateServicesConfig()
    }
    
    private func updateServicesConfig() {
        guard let settings = appSettings.first else { return }
        currentSettings = settings
        
        screenCaptureManager?.setCaptureInterval(settings.captureInterval)
        
        barrageOverlayWindow?.setSpeed(settings.barrageSpeed)
        if let direction = settings.barrageDirection {
            barrageOverlayWindow?.setDirection(direction)
        }
        if let range = settings.barrageTravelRange {
            barrageOverlayWindow?.setTravelRange(range)
        }
        
        if let voiceIdentifier = settings.voiceIdentifier {
            speechSynthesizer?.setVoice(identifier: voiceIdentifier)
        }
        
        barrageQueue?.setSpeechEnabled(settings.speechEnabled)
    }
    
    private func setupStatusBar() {
        DispatchQueue.main.async {
            self.statusBarController = StatusBarController(appState: self.appState)
        }
    }
    
    private func startServices() {
        barrageOverlayWindow?.show()
        
        screenCaptureManager?.startCapturing { image in
            guard let image = image else { return }
            
            Task {
                do {
                    if let aiService = self.aiService {
                        let encouragement = try await aiService.analyzeImage(image: image)
                        
                        self.appState.updateLastEncouragement(encouragement)
                        
                        let message = EncouragementMessage(text: encouragement)
                        self.modelContext.insert(message)
                        
                        // Split text into sentences and add to queue
                        let sentences = encouragement.components(separatedBy: ["。", "！", "？", ".", "!", "?"])
                            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        
                        self.barrageQueue?.enqueueMultiple(sentences)
                    }
                } catch {
                    print("Failed to analyze screenshot: \(error)")
                    
                    let errorMessage = (error as? AIServiceError)?.errorDescription ?? error.localizedDescription
                    self.barrageQueue?.enqueueMultiple([errorMessage], isError: true)
                }
                
                self.appState.setProcessing(false)
            }
        }
    }
    
    private func stopServices() {
        screenCaptureManager?.stopCapturing()
        speechSynthesizer?.stop()
        barrageQueue?.clear()
        barrageOverlayWindow?.clearAllBarrages()
        barrageOverlayWindow?.hide()
    }
    
    private func sendTestBarrages() {
        guard let barrageQueue = barrageQueue else { return }
        barrageOverlayWindow?.show()
        
        let testMessages = [
            "你的代码看起来很优雅！继续加油！",
            "你是解决问题的高手！",
            "这个设计非常出色，继续努力！",
            "看到你的进步真是鼓舞人心！",
            "你的创造性思维令人印象深刻！",
            "这个实现非常优雅！",
            "困难只是暂时的，你一定能克服！",
            "你的专注力令人钦佩！",
            "你处理复杂问题的方式非常出色！",
            "坚持就会成功，你做得很棒！"
        ]
        
        barrageQueue.enqueueMultiple(testMessages)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [AppSettings.self, EncouragementMessage.self, ChatMessage.self], inMemory: true)
        .environmentObject(AppState())
}
