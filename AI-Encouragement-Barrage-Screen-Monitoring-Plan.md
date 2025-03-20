# AI-Encouragement-Barrage 屏幕监控功能重构计划

## 问题描述

当前应用中的循环截屏和生成回复功能存在脱节问题：系统在不停地截图并返回回复，但这些截图没有正确地发送到当前的聊天框中。

## 解决方案概述

1. **屏幕监控功能重构**：
   - 添加明确的屏幕监控状态控制
   - 确保截图结果发送到当前选中的会话中
   - 在UI中添加控制开关

2. **UI优化**：
   - 调整聊天界面的左右分割比例，左边较小，右边较大
   - 在聊天界面上方添加监控开关
   - 在菜单栏也添加相同的开关

## 详细设计

### 1. AppState 修改

```swift
class AppState: ObservableObject {
    // 现有属性
    @Published var isRunning: Bool = false  // 控制弹幕显示
    @Published var isProcessing: Bool = false
    @Published var lastEncouragement: String = ""
    @Published var lastCaptureTime: Date? = nil
    @Published var selectedConversationID: UUID? = nil
    
    // 新增属性
    @Published var isScreenAnalysisActive: Bool = false  // 控制屏幕监控
    
    // 现有方法
    func toggleRunning() {
        isRunning.toggle()
    }
    
    // 新增方法
    func toggleScreenAnalysis() {
        isScreenAnalysisActive.toggle()
    }
}
```

### 2. ScreenCaptureManager 修改

需要修改 ScreenCaptureManager 使其与 AppState 和当前会话集成：

```swift
class ScreenCaptureManager: ObservableObject, @unchecked Sendable {
    // 现有属性
    private var captureTimer: Timer?
    private var captureInterval: TimeInterval
    private var isCapturing: Bool = false
    private var captureHandler: ((CGImage?) -> Void)?
    
    // 新增属性
    private weak var appState: AppState?
    
    // 修改初始化方法
    init(captureInterval: TimeInterval = 20.0, appState: AppState? = nil) {
        self.captureInterval = captureInterval
        self.appState = appState
    }
    
    // 修改开始捕获方法，接收当前会话ID
    func startCapturing(handler: @escaping (CGImage?, UUID?) -> Void) {
        guard !isCapturing else { return }
        
        self.captureHandler = { [weak self] image in
            // 获取当前会话ID
            let conversationID = self?.appState?.selectedConversationID
            handler(image, conversationID)
        }
        
        self.isCapturing = true
        
        // 设置定时器
        captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isCapturing else { return }
            
            // 检查是否启用了屏幕分析
            if self.appState?.isScreenAnalysisActive == true {
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.captureScreen()
                }
            }
        }
        
        // 如果启用了屏幕分析，立即执行一次截屏
        if appState?.isScreenAnalysisActive == true {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.captureScreen()
            }
        }
    }
}
```

### 3. ConversationDetailView 修改

在 ConversationDetailView 中添加屏幕监控开关并处理截图：

```swift
struct ConversationDetailView: View {
    // 现有属性
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @ObservedObject var aiService: AIService
    @ObservedObject var screenCaptureManager: ScreenCaptureManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                // 现有标题代码...
                
                Spacer()
                
                // 屏幕监控开关
                Toggle(isOn: $appState.isScreenAnalysisActive) {
                    Text("屏幕监控")
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
            
            // 其余视图代码...
        }
        .onAppear {
            // 设置截图处理器
            setupScreenCaptureHandler()
        }
    }
    
    // 设置截图处理器
    private func setupScreenCaptureHandler() {
        screenCaptureManager.stopCapturing()  // 先停止现有捕获
        
        // 启动新的捕获，处理器接收图像和会话ID
        screenCaptureManager.startCapturing { [weak self] (image, conversationID) in
            guard let self = self,
                  let image = image,
                  let conversationID = conversationID,
                  let conversation = self.findConversation(with: conversationID) else {
                return
            }
            
            // 处理截图
            self.processScreenCapture(image: image, for: conversation)
        }
    }
    
    // 查找指定ID的会话
    private func findConversation(with id: UUID) -> Conversation? {
        // 实现查找会话的逻辑
        // 可以使用 modelContext 查询或其他方式
        return conversation  // 暂时返回当前会话
    }
    
    // 处理截图
    private func processScreenCapture(image: CGImage, for conversation: Conversation) {
        // 将截图转换为NSImage
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        
        // 将截屏添加到聊天窗口中
        let imageData = nsImage.tiffRepresentation
        let userMessage = ChatMessage(text: "自动屏幕监控", isFromUser: true, imageData: imageData)
        userMessage.conversationID = conversation.id
        
        DispatchQueue.main.async {
            conversation.addMessage(userMessage)
            
            // 分析图像
            Task {
                do {
                    let aiResponse = try await self.aiService.analyzeImage(image: image)
                    
                    DispatchQueue.main.async {
                        let aiMessage = ChatMessage(text: aiResponse, isFromUser: false)
                        conversation.addMessage(aiMessage)
                        
                        // 更新应用状态
                        self.appState.updateLastEncouragement(aiResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        let errorMessage = "AI分析失败: \(error.localizedDescription)"
                        let aiMessage = ChatMessage(text: errorMessage, isFromUser: false)
                        conversation.addMessage(aiMessage)
                    }
                }
            }
        }
    }
}
```

### 4. 菜单栏集成

在应用的主菜单中添加屏幕监控开关：

```swift
// 在适当的菜单构建位置
Menu("控制") {
    Toggle("屏幕监控", isOn: $appState.isScreenAnalysisActive)
    Toggle("弹幕显示", isOn: $appState.isRunning)
}
```

### 5. UI布局优化

根据提供的截图，我们需要优化UI布局，确保左侧较窄（会话列表），右侧较宽（聊天详情）。从截图可以看出，当前的布局已经是左窄右宽，但我们可以进一步优化比例：

```swift
struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            // 左侧会话列表 - 保持窄一些
            ConversationListView()
                .frame(minWidth: 180, idealWidth: 220, maxWidth: 250)
        } detail: {
            // 右侧聊天详情 - 保持宽一些
            ConversationDetailView()
                .frame(minWidth: 550)
        }
        .navigationSplitViewStyle(.balanced) // 确保分割比例合理
    }
}
```

这样的布局与截图中显示的UI风格一致，左侧较窄的会话列表，右侧较宽的聊天详情区域，符合现代聊天应用的设计美感。

## 实施计划

1. **第一阶段：功能修复**
   - 修改 AppState，添加 isScreenAnalysisActive 状态
   - 更新 ScreenCaptureManager，与 AppState 集成
   - 修改 ConversationDetailView，处理自动截图

2. **第二阶段：UI优化**
   - 在 ConversationDetailView 中添加屏幕监控开关
   - 调整分割视图比例
   - 添加菜单栏控制

3. **第三阶段：测试与优化**
   - 测试屏幕监控功能
   - 测试UI布局
   - 根据反馈进行优化