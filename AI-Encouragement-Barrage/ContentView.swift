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
    @State private var dataMigrationHelper: DataMigrationHelper?
    
    // UI state
    @State private var selectedTab = 0
    @State private var testVoiceText: String = "我们很棒，不是吗？"
    @State private var showTestVoicePopup: Bool = false
    @State private var currentSettings: AppSettings = AppSettings()
    @State private var hasMigrated: Bool = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat interface
            if let aiService = aiService, let screenCaptureManager = screenCaptureManager {
                ChatInterfaceView(
                    aiService: aiService,
                    screenCaptureManager: screenCaptureManager
                )
                .tabItem {
                    Label("聊天", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(0)
            }
            
            // Settings interface
            SettingsView(
                testVoiceText: $testVoiceText,
                showTestVoicePopup: $showTestVoicePopup
            )
            .tabItem {
                Label("设置", systemImage: "gear")
            }
            .tag(1)
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            initializeServices()
            setupStatusBar()
            setupNotificationObservers()
            
            // 执行数据迁移
            if !hasMigrated {
                Task {
                    await migrateData()
                    hasMigrated = true
                }
            }
        }
        .onChange(of: appState.isRunning) { _, isRunning in
            if isRunning {
                startServices()
            } else {
                stopServices()
            }
        }
        .onChange(of: appState.isScreenAnalysisActive) { _, isActive in
            print("【日志2】ContentView检测到isScreenAnalysisActive变化: \(isActive)")
            if isActive {
                startScreenAnalysis()
            } else {
                stopScreenAnalysis()
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
        
        // 创建弹幕服务
        let barrageService = BarrageService(modelContext: modelContext)
        appState.barrageService = barrageService
        
        // 创建弹幕窗口
        barrageOverlayWindow = BarrageOverlayWindow()
        speechSynthesizer = SpeechSynthesizer()
        
        // 创建数据迁移助手
        dataMigrationHelper = DataMigrationHelper(modelContext: modelContext)
        
        if let barrageOverlayWindow = barrageOverlayWindow,
           let speechSynthesizer = speechSynthesizer {
            // 初始化弹幕队列
            barrageQueue = BarrageQueue(
                barrageWindow: barrageOverlayWindow,
                speechSynthesizer: speechSynthesizer
            )
            barrageQueue?.setSpeechEnabled(settings.speechEnabled)
            
            // 初始化其他服务
            screenCaptureManager = ScreenCaptureManager(captureInterval: settings.captureInterval)
            aiService = AIService(settings: settings, barrageService: barrageService)
            
            // 设置自定义语音
            if let voiceIdentifier = settings.voiceIdentifier {
                speechSynthesizer.setVoice(identifier: voiceIdentifier)
            }
            
            // 设置弹幕速度和方向
            barrageOverlayWindow.setSpeed(settings.barrageSpeed)
            if let direction = settings.barrageDirection {
                barrageOverlayWindow.setDirection(direction)
            }
            if let range = settings.barrageTravelRange {
                barrageOverlayWindow.setTravelRange(range)
            }
            
            // 检查屏幕捕获权限
            if let screenCaptureManager = screenCaptureManager {
                if !screenCaptureManager.checkScreenCapturePermission() {
                    screenCaptureManager.requestScreenCapturePermission()
                }
            }
        }
    }
    
    private func migrateData() async {
        do {
            try await dataMigrationHelper?.migrateChatsToConversations()
        } catch {
            print("数据迁移失败: \(error.localizedDescription)")
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
    // 启动屏幕分析功能 - 将截屏结果发送到当前会话
    private func startScreenAnalysis() {
        print("【日志3】启动屏幕分析功能")
        
        // 使用设置中的截图间隔
        let captureInterval = currentSettings.captureInterval
        print("【日志4】设置截图间隔: \(captureInterval)秒")
        screenCaptureManager?.setCaptureInterval(captureInterval)
        
        // 检查screenCaptureManager是否为nil
        if screenCaptureManager == nil {
            print("【错误】screenCaptureManager为nil")
            return
        }
        
        // 启动截图功能，将截图发送到当前选中的会话
        print("【日志5】调用screenCaptureManager.startCapturing")
        screenCaptureManager?.startCapturing { [self] image in
            print("【日志6】截图回调被触发")
            
            guard let image = image else {
                print("【错误】截图为nil")
                return
            }
            print("【日志7】成功获取截图，尺寸: \(image.width) x \(image.height)")
            
            // 获取当前选中的会话ID
            guard let selectedID = appState.selectedConversationID else {
                print("【错误】没有选中的会话，无法发送截屏")
                return
            }
            print("【日志8】当前选中的会话ID: \(selectedID)")
            
            // 将截屏转换为NSImage
            print("【日志9】将CGImage转换为NSImage")
            let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
            let imageData = nsImage.tiffRepresentation
            
            if imageData == nil {
                print("【错误】无法获取图像数据")
                return
            }
            print("【日志10】成功获取图像数据，大小: \(imageData?.count ?? 0) 字节")
            
            // 使用NotificationCenter发送截图到当前会话
            print("【日志11】发送ScreenCaptureReceived通知")
            NotificationCenter.default.post(
                name: NSNotification.Name("ScreenCaptureReceived"),
                object: nil,
                userInfo: [
                    "conversationID": selectedID,
                    "imageData": imageData as Any,
                    "timestamp": Date()
                ]
            )
            
            // 分析图像
            print("【日志12】开始分析图像")
            Task {
                do {
                    if let aiService = self.aiService {
                        print("【日志13】调用aiService.analyzeImage")
                        let aiResponse = try await aiService.analyzeImage(image: image)
                        print("【日志14】AI分析完成: \(aiResponse.prefix(50))...")
                        
                        // 更新最新鼓励消息
                        self.appState.updateLastEncouragement(aiResponse)
                        
                        // 添加到弹幕队列
                        let sentences = aiResponse.components(separatedBy: ["。", "！", "？", ".", "!", "?"])
                            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        
                        print("【日志15】添加到弹幕队列: \(sentences.count) 条消息")
                        self.barrageQueue?.enqueueMultiple(sentences)
                        
                        // 发送AI回复到当前会话
                        print("【日志16】发送AIResponseReceived通知")
                        NotificationCenter.default.post(
                            name: NSNotification.Name("AIResponseReceived"),
                            object: nil,
                            userInfo: [
                                "conversationID": selectedID,
                                "response": aiResponse,
                                "timestamp": Date()
                            ]
                        )
                    } else {
                        print("【错误】aiService为nil")
                    }
                } catch {
                    print("【错误】处理截屏失败: \(error.localizedDescription)")
                }
            }
        }
    }
    // 停止屏幕分析功能
    private func stopScreenAnalysis() {
        print("【日志17】停止屏幕分析功能")
        if screenCaptureManager == nil {
            print("【错误】screenCaptureManager为nil，无法停止截图")
        } else {
            screenCaptureManager?.stopCapturing()
            print("【日志18】已调用screenCaptureManager.stopCapturing()")
        }
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
        .modelContainer(for: [AppSettings.self, EncouragementMessage.self, ChatMessage.self, Conversation.self], inMemory: true)
        .environmentObject(AppState())
}
