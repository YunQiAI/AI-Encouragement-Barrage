//
//  ScreenCaptureManager.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import AppKit
import CoreGraphics
import ScreenCaptureKit
import Combine

// 使用@unchecked Sendable来避免Swift 6中的Sendable错误
class ScreenCaptureManager: @unchecked Sendable {
    private var captureTimer: Timer?
    private var captureInterval: TimeInterval
    private var isCapturing: Bool = false
    private var captureHandler: ((CGImage?) -> Void)?
    
    // ScreenCaptureKit相关属性
    private var captureEngine: SCStreamCapture?
    private var stream: SCStream?
    private var availableContent: SCShareableContent?
    private var streamConfiguration: SCStreamConfiguration
    private var cancellables = Set<AnyCancellable>()
    
    init(captureInterval: TimeInterval = 20.0) {
        self.captureInterval = captureInterval
        self.streamConfiguration = SCStreamConfiguration()
        
        // 配置捕获质量和性能
        streamConfiguration.width = 1920  // 可以根据需要调整
        streamConfiguration.height = 1080 // 可以根据需要调整
        streamConfiguration.minimumFrameInterval = CMTime(value: 1, timescale: 1) // 每秒1帧，足够分析使用
        streamConfiguration.queueDepth = 1 // 最小队列深度，减少内存使用
        
        // 初始化时加载可用内容
        Task {
            await loadAvailableContent()
        }
    }
    
    func startCapturing(handler: @escaping (CGImage?) -> Void) {
        guard !isCapturing else { return }
        
        self.captureHandler = handler
        self.isCapturing = true
        
        // 设置定时器，定期执行截屏
        captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isCapturing else { return }
            
            Task { [weak self] in
                guard let self = self else { return }
                await self.captureScreenWithSCK()
            }
        }
        
        // 立即执行一次截屏
        Task { [weak self] in
            guard let self = self else { return }
            await self.captureScreenWithSCK()
        }
    }
    
    func stopCapturing() {
        isCapturing = false
        captureTimer?.invalidate()
        captureTimer = nil
        captureHandler = nil
        
        // 停止ScreenCaptureKit流
        stopStream()
    }
    
    func setCaptureInterval(_ interval: TimeInterval) {
        self.captureInterval = interval
        
        // 如果正在捕获，重新启动定时器
        if isCapturing, let handler = captureHandler {
            stopCapturing()
            startCapturing(handler: handler)
        }
    }
    
    // 使用ScreenCaptureKit加载可用的捕获内容
    private func loadAvailableContent() async {
        do {
            self.availableContent = try await SCShareableContent.current
        } catch {
            print("加载可用捕获内容失败: \(error)")
        }
    }
    
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
                        DispatchQueue.main.async { [weak self] in
                            self?.captureHandler?(image)
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
    
    // 停止ScreenCaptureKit流
    private func stopStream() {
        Task { [weak self] in
            guard let stream = self?.stream else { return }
            do {
                try await stream.stopCapture()
                self?.stream = nil
                self?.captureEngine = nil
            } catch {
                print("停止捕获流失败: \(error)")
            }
        }
    }
    
    // 检查是否有屏幕录制权限
    func checkScreenCapturePermission() -> Bool {
        // 在macOS中，截屏权限是通过辅助功能权限来控制的
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    // 请求屏幕录制权限
    func requestScreenCapturePermission() {
        // 首先检查ScreenCaptureKit权限
        Task {
            do {
                // 尝试获取当前可共享内容，这会触发权限请求
                _ = try await SCShareableContent.current
            } catch {
                print("请求ScreenCaptureKit权限失败: \(error)")
                
                // 如果ScreenCaptureKit权限请求失败，回退到辅助功能权限
                DispatchQueue.main.async {
                    let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
                    let options = [checkOptPrompt: true] as CFDictionary
                    AXIsProcessTrustedWithOptions(options)
                }
            }
        }
    }
}

// 定义 SCStreamOutputScreen 类
class SCStreamOutputScreen {
    let sampleBuffer: CMSampleBuffer
    
    init(sampleBuffer: CMSampleBuffer) {
        self.sampleBuffer = sampleBuffer
    }
    
    var image: CGImage? {
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[CFString: Any]],
              let attachment = attachments.first else {
            return nil
        }
        
        let key = Unmanaged.passUnretained(kCMSampleAttachmentKey_IsDependedOnByOthers).toOpaque()
        
        // 检查键是否存在，并确保它不是依赖于其他帧的
        guard CFDictionaryContainsKey(attachment as CFDictionary, key),
              let value = CFDictionaryGetValue(attachment as CFDictionary, key),
              CFBooleanGetValue((value as! CFBoolean)) == false,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}

// ScreenCaptureKit流捕获处理器
class SCStreamCapture: NSObject, SCStreamOutput {
    var onScreenOutput: ((SCStreamOutputScreen) -> Void)?
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let onScreenOutput = onScreenOutput else { return }
        
        // 创建屏幕输出对象
        let screenOutput = SCStreamOutputScreen(sampleBuffer: sampleBuffer)
        onScreenOutput(screenOutput)
    }
    
    // 请求捕获单帧图像
    func captureImage() {
        // 这个方法会触发stream(_:didOutputSampleBuffer:of:)回调
        // 实际上不需要做任何事情，因为流会自动提供下一帧
    }
}
