# AI鼓励弹幕应用开发计划

## 1. 系统架构设计

### 1.1 整体架构

系统由以下几个主要模块组成：
- 截屏模块：负责定期捕获屏幕内容
- AI分析模块：使用Ollama API分析截图并生成鼓励语
- 弹幕显示模块：将鼓励语以弹幕形式显示在屏幕上
- 语音合成模块：朗读生成的鼓励语
- 设置模块：管理应用配置
- 状态管理：控制应用的运行状态

模块之间的关系如下：
```
截屏模块 → AI分析模块 → 弹幕显示模块
                    → 语音合成模块
设置模块 → 控制所有其他模块
状态管理 → 控制所有其他模块
```

### 1.2 模块详细设计

#### 1.2.1 截屏模块

```swift
class ScreenCaptureManager {
    private var captureTimer: Timer?
    private var captureInterval: TimeInterval
    private var isCapturing: Bool
    
    func startCapturing()
    func stopCapturing()
    func setCaptureInterval(interval: TimeInterval)
    func captureScreen() -> CGImage?
}
```

#### 1.2.2 AI分析模块

```swift
class OllamaService {
    private let baseURL: String
    private let modelName: String
    
    func analyzeImage(image: CGImage) async throws -> String
    private func sendRequest(prompt: String, image: Data) async throws -> String
}
```

#### 1.2.3 弹幕显示模块

```swift
class BarrageManager {
    private var activeBarrages: [BarrageItem]
    private var speed: Double
    
    func addBarrage(text: String)
    func clearAllBarrages()
    func setSpeed(speed: Double)
}

struct BarrageItem: Identifiable {
    let id: UUID
    let text: String
    var position: CGPoint
    var opacity: Double
    var direction: Direction
    
    mutating func animate()
    
    enum Direction {
        case leftToRight
        case rightToLeft
    }
}
```

#### 1.2.4 语音合成模块

```swift
class SpeechSynthesizer {
    private let synthesizer: AVSpeechSynthesizer
    private var isSpeaking: Bool
    private var voiceStyle: VoiceStyle
    
    func speak(text: String)
    func stop()
    func setVoiceStyle(style: VoiceStyle)
    
    enum VoiceStyle {
        case `default`
        case warm
        case deep
        case energetic
    }
}
```

#### 1.2.5 设置模块

```swift
class AppSettings {
    var captureInterval: Double  // 截屏间隔（秒）
    var speechEnabled: Bool      // 是否启用语音
    var voiceStyle: VoiceStyle   // 语音风格
    var barrageSpeed: Double     // 弹幕速度
    var isActive: Bool           // 应用是否活跃
    
    func save()
    func load()
}
```

#### 1.2.6 状态管理

```swift
class AppState: ObservableObject {
    @Published var isRunning: Bool
    @Published var isProcessing: Bool
    @Published var lastEncouragement: String
    @Published var lastCaptureTime: Date?
    
    func toggleRunning()
    func setProcessing(isProcessing: Bool)
    func updateLastEncouragement(text: String)
}
```

## 2. 数据流设计

应用的主要数据流程如下：

1. 用户启动应用，初始化各个模块
2. 截屏模块按设定的时间间隔捕获屏幕
3. 捕获的截图发送给AI分析模块
4. AI分析模块使用Ollama API分析截图，生成鼓励语
5. 生成的鼓励语发送给弹幕显示模块和语音合成模块
6. 弹幕显示模块将鼓励语以弹幕形式显示在屏幕上
7. 语音合成模块朗读鼓励语
8. 用户可以通过设置模块调整各种参数

## 3. 数据模型设计

我们需要重新设计数据模型，以适应应用的需求：

```swift
// 替代当前的Item模型
@Model
final class EncouragementMessage {
    var id: UUID
    var text: String
    var timestamp: Date
    var context: String?  // 可选，记录生成这条消息时的上下文
    
    init(text: String, context: String? = nil) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.context = context
    }
}

// 应用设置模型
@Model
final class AppSettings {
    var captureInterval: Double  // 截屏间隔（秒）
    var speechEnabled: Bool      // 是否启用语音
    var voiceStyle: String       // 语音风格
    var barrageSpeed: Double     // 弹幕速度
    var isActive: Bool           // 应用是否活跃
    
    init() {
        self.captureInterval = 20.0
        self.speechEnabled = true
        self.voiceStyle = "default"
        self.barrageSpeed = 1.0
        self.isActive = false
    }
}
```

## 4. UI设计

### 4.1 主界面设计

主界面将包含以下元素：
- 无固定窗口，弹幕直接显示在屏幕上
- 菜单栏图标，用于控制应用

```swift
struct BarrageOverlayWindow {
    private var window: NSWindow
    private var barrages: [BarrageItem]
    
    func show()
    func hide()
    func addBarrage(text: String)
}

struct StatusBarController {
    private var statusItem: NSStatusItem
    
    func setupMenu()
    func toggleActive()
    func showSettings()
}
```

### 4.2 设置界面设计

设置界面将包含以下元素：
- 截屏间隔调节滑块
- 弹幕速度调节滑块
- 语音朗读开关
- 语音风格选择器
- 启动/停止按钮

```swift
struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var appState: AppState
    
    var body: some View {
        Form {
            Section("截屏设置") {
                Slider(value: $settings.captureInterval, in: 5...60, step: 5) {
                    Text("截屏间隔: \(Int(settings.captureInterval))秒")
                }
            }
            
            Section("弹幕设置") {
                Slider(value: $settings.barrageSpeed, in: 0.5...2.0, step: 0.1) {
                    Text("弹幕速度: \(settings.barrageSpeed, specifier: "%.1f")x")
                }
            }
            
            Section("语音设置") {
                Toggle("启用语音朗读", isOn: $settings.speechEnabled)
                
                Picker("语音风格", selection: $settings.voiceStyle) {
                    Text("默认").tag("default")
                    Text("温暖").tag("warm")
                    Text("低沉").tag("deep")
                    Text("高能量").tag("energetic")
                }
                .disabled(!settings.speechEnabled)
            }
            
            Button(appState.isRunning ? "停止" : "启动") {
                appState.toggleRunning()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 300, height: 400)
    }
}
```

## 5. 实现步骤

### 阶段1：基础架构搭建（1周）

1. **项目重构**
   - 移除现有的Item模型，创建新的数据模型
   - 设计应用的基本架构
   - 创建必要的服务类和管理器类

2. **截屏功能实现**
   - 实现`ScreenCaptureManager`类
   - 添加必要的权限请求
   - 实现定时截屏功能

3. **Ollama API集成**
   - 实现`OllamaService`类
   - 添加与Ollama API的通信功能
   - 实现图像分析和文本生成功能

### 阶段2：核心功能实现（2周）

4. **弹幕显示功能**
   - 实现`BarrageManager`和`BarrageItem`类
   - 创建弹幕动画效果
   - 实现弹幕的随机位置和方向

5. **语音合成功能**
   - 实现`SpeechSynthesizer`类
   - 添加不同语音风格的支持
   - 实现文本朗读功能

6. **设置界面**
   - 实现设置视图
   - 添加各种设置项的控制
   - 实现设置的保存和加载

### 阶段3：集成与优化（1周）

7. **功能集成**
   - 将所有模块连接起来
   - 实现完整的工作流程
   - 添加错误处理和恢复机制

8. **性能优化**
   - 优化截屏频率和处理流程
   - 减少资源占用
   - 提高响应速度

9. **用户体验改进**
   - 添加动画和过渡效果
   - 优化弹幕显示效果
   - 改进设置界面的易用性

## 6. 技术挑战与解决方案

### 6.1 截屏权限

**挑战**：macOS对截屏有严格的权限控制。

**解决方案**：
- 使用`CGWindowListCreateImage`进行无干扰截屏
- 在应用首次运行时请求必要的权限
- 在Info.plist中添加适当的权限描述

```swift
func requestScreenCapturePermission() {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString: true]
    AXIsProcessTrustedWithOptions(options)
}
```

### 6.2 全屏弹幕

**挑战**：在macOS上创建全屏覆盖层而不干扰用户操作。

**解决方案**：
- 使用`NSWindow`的`level`属性设置为`NSWindow.Level.screenSaver`
- 将`ignoresMouseEvents`设置为`true`
- 使用透明背景，只显示弹幕文字

```swift
func setupOverlayWindow() {
    let window = NSWindow(
        contentRect: NSScreen.main!.frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    window.backgroundColor = .clear
    window.isOpaque = false
    window.hasShadow = false
    window.level = .screenSaver
    window.ignoresMouseEvents = true
    
    self.window = window
}
```

### 6.3 AI响应延迟

**挑战**：本地AI模型分析可能需要时间，导致响应延迟。

**解决方案**：
- 实现异步处理，使用队列管理截屏和分析请求
- 使用Swift的async/await机制处理异步操作
- 添加超时机制，避免长时间等待

```swift
func processScreenCapture() async {
    guard let image = captureScreen() else { return }
    
    do {
        let encouragement = try await withTimeout(seconds: 10) {
            try await ollamaService.analyzeImage(image: image)
        }
        
        await MainActor.run {
            barrageManager.addBarrage(text: encouragement)
            if settings.speechEnabled {
                speechSynthesizer.speak(text: encouragement)
            }
        }
    } catch {
        print("Error processing screen capture: \(error)")
    }
}

func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
```

## 7. 权限需求

应用将需要以下权限：

1. **屏幕录制权限**
   - 用于截屏功能
   - 需要在Info.plist中添加`NSScreenCaptureUsageDescription`

2. **辅助功能权限**
   - 用于创建全屏覆盖层
   - 需要在应用首次运行时请求

3. **网络权限**
   - 用于与本地Ollama API通信
   - 需要在Info.plist中添加`NSAppTransportSecurity`

4. **语音合成权限**
   - 用于朗读鼓励语
   - 系统默认允许，无需特殊处理

## 8. 测试计划

### 8.1 单元测试

- 测试截屏功能是否正常工作
- 测试Ollama API通信是否正常
- 测试弹幕动画效果
- 测试语音合成功能

### 8.2 集成测试

- 测试从截屏到弹幕显示的完整流程
- 测试设置变更对各模块的影响
- 测试错误处理和恢复机制

### 8.3 性能测试

- 测试不同截屏频率下的CPU和内存使用情况
- 测试AI分析的响应时间
- 测试同时显示多个弹幕时的性能

### 8.4 用户体验测试

- 测试弹幕是否干扰正常工作
- 评估语音朗读的自然度和适时性
- 测试设置界面的易用性

## 9. 未来扩展计划

### 9.1 语音输入功能

- 添加语音识别功能，允许用户通过语音与AI交互
- 实现双向对话模式

### 9.2 快捷键支持

- 添加全局快捷键，用于控制应用
- 允许用户自定义快捷键

### 9.3 主题/样式自定义

- 添加多种弹幕样式
- 允许用户自定义颜色、字体和动画效果

### 9.4 多显示器支持

- 扩展弹幕显示到所有连接的显示器
- 允许用户选择要显示弹幕的显示器