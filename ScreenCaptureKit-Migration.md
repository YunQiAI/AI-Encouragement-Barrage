# 从CGWindowListCreateImage迁移到ScreenCaptureKit

## 背景

在编译项目时，我们收到了以下警告：

```
'CGWindowListCreateImage' was deprecated in macOS 14.0: Please use ScreenCaptureKit instead.
```

这表明我们使用的屏幕捕获方法已在macOS 14.0中被废弃，Apple建议使用ScreenCaptureKit框架代替。

## 迁移内容

我们对`ScreenCaptureManager`类进行了以下更改：

### 1. 框架迁移

- **之前**：使用CoreGraphics框架中的`CGWindowListCreateImage`函数
- **之后**：使用ScreenCaptureKit框架中的`SCStream`和相关API

### 2. 功能增强

- **更高效的捕获**：使用流式API，只在需要时捕获屏幕内容
- **更好的性能控制**：可配置捕获分辨率、帧率等参数
- **更强的错误处理**：使用现代Swift错误处理机制

### 3. 权限管理

- **更新Info.plist**：已包含`NSScreenCaptureUsageDescription`权限描述
- **更新Entitlements**：添加`com.apple.security.screen-recording`权限
- **双重权限检查**：同时支持ScreenCaptureKit权限和传统辅助功能权限

## 代码对比

### 之前的实现（使用CGWindowListCreateImage）

```swift
func captureScreen() -> CGImage? {
    // 获取主屏幕
    guard let mainScreen = NSScreen.main else { return nil }
    
    // 创建截图
    let screenRect = mainScreen.frame
    let cgScreenRect = CGRect(x: 0, y: 0, width: screenRect.width, height: screenRect.height)
    
    // 使用CGWindowListCreateImage进行无干扰截屏
    let screenshot = CGWindowListCreateImage(cgScreenRect, .optionOnScreenOnly, kCGNullWindowID, [])
    
    return screenshot
}
```

### 现在的实现（使用ScreenCaptureKit）

```swift
// 使用ScreenCaptureKit捕获屏幕
private func captureScreenWithSCK() async {
    // 确保已加载可用内容
    if availableContent == nil {
        await loadAvailableContent()
    }
    
    guard let availableContent = availableContent,
          let mainDisplay = availableContent.displays.first else {
        return
    }
    
    // 如果流不存在，创建并启动流
    if stream == nil {
        do {
            // 配置过滤器，只捕获主显示器
            let filter = SCContentFilter(display: mainDisplay, excludingApplications: [], exceptingWindows: [])
            
            // 创建流
            stream = SCStream(filter: filter, configuration: streamConfiguration, delegate: nil)
            
            // 创建捕获引擎
            captureEngine = SCStreamCapture()
            
            // 添加流输出处理器
            try stream?.addStreamOutput(captureEngine!, type: .screen, sampleHandlerQueue: .main)
            
            // 启动流
            try await stream?.startCapture()
            
            // 设置捕获回调
            captureEngine?.onScreenOutput = { [weak self] output in
                guard let self = self, self.isCapturing else { return }
                
                // 获取捕获的图像
                if let image = output.image {
                    DispatchQueue.main.async {
                        self.captureHandler?(image)
                    }
                }
            }
        } catch {
            print("创建或启动捕获流失败: \(error)")
        }
    } else {
        // 如果流已存在，请求一帧
        captureEngine?.captureImage()
    }
}
```

## 优势

1. **未来兼容性**：使用Apple推荐的最新API，避免未来版本中的废弃警告
2. **性能优化**：ScreenCaptureKit提供更高效的屏幕捕获，减少资源消耗
3. **更多功能**：可以更精细地控制捕获内容，例如排除特定应用程序或窗口
4. **更好的用户体验**：更现代的权限请求流程

## 注意事项

1. **最低系统要求**：ScreenCaptureKit要求macOS 12.3或更高版本
2. **权限处理**：应用程序需要请求屏幕录制权限
3. **异步API**：新实现使用Swift的async/await，需要在Task中调用

## 结论

通过迁移到ScreenCaptureKit，我们不仅解决了废弃API的警告，还提高了应用程序的性能和功能。这是一个值得的升级，使我们的应用程序更加现代化和高效。