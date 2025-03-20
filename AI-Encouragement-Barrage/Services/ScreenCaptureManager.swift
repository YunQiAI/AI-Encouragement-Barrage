//
//  ScreenCaptureManager.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import AppKit
import CoreGraphics
import Combine
import ScreenCaptureKit

// 使用@unchecked Sendable来避免Swift 6中的Sendable错误
class ScreenCaptureManager: ObservableObject, @unchecked Sendable {
    private var captureTimer: Timer?
    private var captureInterval: TimeInterval
    private var isCapturing: Bool = false
    private var captureHandler: ((CGImage?) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
    // ScreenCaptureKit 相关属性
    private var captureEngine: SCShareableContent?
    private var streamConfiguration: SCStreamConfiguration?
    private var captureStream: SCStream?
    private var streamOutput: ScreenCaptureStreamOutput?
    
    init(captureInterval: TimeInterval = 20.0) {
        self.captureInterval = captureInterval
    }
    
    func startCapturing(handler: @escaping (CGImage?) -> Void) {
        guard !isCapturing else { return }
        
        self.captureHandler = handler
        self.isCapturing = true
        
        // 设置定时器，定期执行截屏
        captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isCapturing else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.captureScreen()
            }
        }
        
        // 立即执行一次截屏
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.captureScreen()
        }
    }
    
    func stopCapturing() {
        isCapturing = false
        captureTimer?.invalidate()
        captureTimer = nil
        captureHandler = nil
        
        // 停止 ScreenCaptureKit 流
        stopScreenCaptureStream()
    }
    
    func setCaptureInterval(_ interval: TimeInterval) {
        self.captureInterval = interval
        
        // 如果正在捕获，重新启动定时器
        if isCapturing, let handler = captureHandler {
            stopCapturing()
            startCapturing(handler: handler)
        }
    }
    
    // 捕获屏幕
    @MainActor
    private func captureScreen() {
        // 获取主屏幕尺寸
        guard let screen = NSScreen.main else {
            print("无法获取主屏幕")
            return
        }
        
        let rect = screen.frame
        let captureRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        
        // 尝试使用 ScreenCaptureKit
        Task {
            do {
                try await setupScreenCaptureStream()
                // ScreenCaptureKit 流已设置，将通过 streamOutput 回调获取图像
            } catch {
                print("ScreenCaptureKit 设置失败: \(error.localizedDescription)")
                
                // 回退到旧方法
                #if os(macOS)
                print("ScreenCaptureKit 设置失败，无法捕获屏幕内容")
                // 通知处理程序捕获失败
                self.captureHandler?(nil)
                #endif
            }
        }
    }
    
    // 设置 ScreenCaptureKit 流
    private func setupScreenCaptureStream() async throws {
        // 如果已经设置了流，则不需要重新设置
        if captureStream != nil {
            return
        }
        
        // 获取可共享内容
        let content = try await SCShareableContent.current
        captureEngine = content
        
        // 获取主显示器
        guard let display = content.displays.first else {
            throw NSError(domain: "ScreenCaptureManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "没有找到可用的显示器"])
        }
        
        // 创建流配置
        let configuration = SCStreamConfiguration()
        configuration.width = display.width * 2  // 考虑 Retina 显示器
        configuration.height = display.height * 2
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 30)  // 30 FPS
        configuration.showsCursor = true
        streamConfiguration = configuration
        
        // 创建流输出处理器
        let output = ScreenCaptureStreamOutput()
        output.captureHandler = { [weak self] image in
            self?.captureHandler?(image)
        }
        streamOutput = output
        
        // 创建并启动流
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        
        try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: .main)
        try await stream.startCapture()
        
        captureStream = stream
    }
    
    // 停止 ScreenCaptureKit 流
    private func stopScreenCaptureStream() {
        Task {
            if let stream = captureStream {
                do {
                    try await stream.stopCapture()
                } catch {
                    print("停止屏幕捕获流失败: \(error.localizedDescription)")
                }
                captureStream = nil
            }
            streamOutput = nil
            streamConfiguration = nil
            captureEngine = nil
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
        DispatchQueue.main.async {
            let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
            let options = [checkOptPrompt: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }
    
    // 手动触发一次截屏
    func captureScreenNow(completion: ((CGImage?) -> Void)? = nil) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // 保存原始处理程序
            let originalHandler = self.captureHandler
            
            // 如果提供了完成处理程序，则临时替换
            if let completion = completion {
                self.captureHandler = { image in
                    completion(image)
                    // 恢复原始处理程序
                    self.captureHandler = originalHandler
                }
            }
            
            self.captureScreen()
        }
    }
}

// ScreenCaptureKit 流输出处理器
class ScreenCaptureStreamOutput: NSObject, SCStreamOutput {
    var captureHandler: ((CGImage?) -> Void)?
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, let captureHandler = captureHandler else { return }
        
        // 从样本缓冲区获取图像
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }
        
        // 创建 CIImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // 创建 CGImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        // 调用处理程序
        captureHandler(cgImage)
    }
}
