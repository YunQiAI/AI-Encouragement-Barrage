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
    
    // 新增属性：AppState引用
    private weak var appState: AppState?
    
    init(captureInterval: TimeInterval = 20.0, appState: AppState? = nil) {
        self.captureInterval = captureInterval
        self.appState = appState
        
        // 监听AppState中isScreenAnalysisActive的变化
        if let appState = appState {
            appState.$isScreenAnalysisActive
                .sink { [weak self] isActive in
                    if isActive {
                        print("【日志1】屏幕监控已激活")
                        // 如果已经在捕获中，不需要重新启动
                        if !(self?.isCapturing ?? false) {
                            self?.startCapturing { _ in }
                        }
                    } else {
                        print("屏幕监控已停止")
                        self?.stopCapturing()
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    func startCapturing(handler: @escaping (CGImage?) -> Void) {
        print("【ScreenCaptureManager】开始启动截图功能")
        guard !isCapturing else {
            print("【ScreenCaptureManager】已经在截图中，忽略此次调用")
            return
        }
        
        self.captureHandler = handler
        self.isCapturing = true
        
        print("【ScreenCaptureManager】设置定时器，间隔: \(captureInterval)秒")
        // 设置定时器，定期执行截屏
        captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isCapturing else {
                print("【ScreenCaptureManager】定时器触发，但已停止截图")
                return
            }
            
            // 只有当屏幕监控激活时才执行截屏
            if self.appState?.isScreenAnalysisActive == true {
                print("【ScreenCaptureManager】定时器触发截图")
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.captureScreen()
                }
            } else {
                print("【ScreenCaptureManager】屏幕监控未激活，跳过本次截图")
            }
        }
        
        // 立即执行第一次截图
        print("【ScreenCaptureManager】准备执行首次截图")
        Task { @MainActor in
            print("【ScreenCaptureManager】开始执行首次截图")
            self.captureScreen()
        }
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
        print("【ScreenCaptureManager】开始captureScreen")
        
        // 获取主屏幕尺寸
        guard let screen = NSScreen.main else {
            print("【错误】无法获取主屏幕")
            return
        }
        
        // 获取屏幕尺寸（仅用于日志记录）
        let rect = screen.frame
        print("【ScreenCaptureManager】屏幕尺寸: \(rect.width) x \(rect.height)")
        
        // 检查是否已经有活跃的截图流
        if captureStream != nil {
            print("【ScreenCaptureManager】已存在活跃的截图流")
            return
        }
        
        // 检查权限
        // if !checkScreenCapturePermission() {
        //     print("【错误】没有屏幕捕获权限，请授权")
        //     requestScreenCapturePermission()
        //     return
        // }
        
        // 尝试使用 ScreenCaptureKit
        print("【ScreenCaptureManager】开始设置ScreenCaptureKit流")
        Task {
            do {
                try await setupScreenCaptureStream()
                print("【ScreenCaptureManager】成功设置ScreenCaptureKit流")
            } catch {
                print("【错误】ScreenCaptureKit设置失败: \(error.localizedDescription)")
                
                // 回退到旧方法
                #if os(macOS)
                print("【错误】ScreenCaptureKit设置失败，无法捕获屏幕内容")
                // 通知处理程序捕获失败
                self.captureHandler?(nil)
                #endif
            }
        }
    }
    
    // 设置 ScreenCaptureKit 流
    private func setupScreenCaptureStream() async throws {
        print("【ScreenCaptureManager】开始setupScreenCaptureStream")
        
        // 如果已经设置了流，则不需要重新设置
        if captureStream != nil {
            print("【ScreenCaptureManager】已存在截图流，跳过设置")
            return
        }
        
        // 获取可共享内容
        print("【ScreenCaptureManager】获取可共享内容")
        let content = try await SCShareableContent.current
        captureEngine = content
        
        // 获取主显示器
        guard let display = content.displays.first else {
            print("【错误】没有找到可用的显示器")
            throw NSError(domain: "ScreenCaptureManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "没有找到可用的显示器"])
        }
        print("【ScreenCaptureManager】找到显示器: \(display.width) x \(display.height)")
        
        // 创建流配置
        print("【ScreenCaptureManager】创建流配置")
        let configuration = SCStreamConfiguration()
        configuration.width = display.width * 2  // 考虑 Retina 显示器
        configuration.height = display.height * 2
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 2)  // 降低帧率到2 FPS
        configuration.showsCursor = true
        streamConfiguration = configuration
        
        // 创建流输出处理器
        print("【ScreenCaptureManager】创建流输出处理器")
        let output = ScreenCaptureStreamOutput()
        output.captureHandler = { [weak self] image in
            print("【ScreenCaptureManager】收到截图回调")
            self?.captureHandler?(image)
        }
        streamOutput = output
        
        // 创建并启动流
        print("【ScreenCaptureManager】创建和配置截图流")
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        
        print("【ScreenCaptureManager】添加流输出")
        try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: .main)
        
        print("【ScreenCaptureManager】启动截图流")
        try await stream.startCapture()
        
        captureStream = stream
        print("【ScreenCaptureManager】截图流设置完成")
    }
    
    // 停止 ScreenCaptureKit 流
    private func stopScreenCaptureStream() {
        print("【ScreenCaptureManager】开始停止截图流")
        Task {
            if let stream = captureStream {
                do {
                    print("【ScreenCaptureManager】停止现有截图流")
                    try await stream.stopCapture()
                    print("【ScreenCaptureManager】截图流已停止")
                } catch {
                    print("【错误】停止屏幕捕获流失败: \(error.localizedDescription)")
                }
            } else {
                print("【ScreenCaptureManager】没有活跃的截图流")
            }
            
            print("【ScreenCaptureManager】清理资源")
            captureStream = nil
            streamOutput = nil
            streamConfiguration = nil
            captureEngine = nil
            print("【ScreenCaptureManager】所有资源已清理完毕")
        }
    }
    
    func stopCapturing() {
        print("【ScreenCaptureManager】开始停止截图功能")
        isCapturing = false
        
        print("【ScreenCaptureManager】停止定时器")
        captureTimer?.invalidate()
        captureTimer = nil
        
        print("【ScreenCaptureManager】清除回调")
        captureHandler = nil
        
        print("【ScreenCaptureManager】停止截图流")
        stopScreenCaptureStream()
        
        print("【ScreenCaptureManager】截图功能已完全停止")
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
    
    // 手动触发一次截屏，并返回当前会话ID
    func captureScreenNow(completion: ((CGImage?, UUID?) -> Void)? = nil) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // 保存原始处理程序
            let originalHandler = self.captureHandler
            
            // 如果提供了完成处理程序，则临时替换
            if let completion = completion {
                self.captureHandler = { [weak self] image in
                    // 获取当前会话ID
                    let conversationID = self?.appState?.selectedConversationID
                    print("截图完成，当前会话ID: \(String(describing: conversationID))")
                    completion(image, conversationID)
                    
                    // 恢复原始处理程序
                    self?.captureHandler = originalHandler
                }
            }
            
            self.captureScreen()
        }
    }
}

// ScreenCaptureKit 流输出处理器
class ScreenCaptureStreamOutput: NSObject, SCStreamOutput {
    var captureHandler: ((CGImage?) -> Void)?
    private var frameCount: Int = 0
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        frameCount += 1
        print("【ScreenCaptureStreamOutput】收到第 \(frameCount) 帧")
        
        guard type == .screen else {
            print("【ScreenCaptureStreamOutput】忽略非屏幕类型的采样缓冲区")
            return
        }
        
        guard let captureHandler = captureHandler else {
            print("【ScreenCaptureStreamOutput】没有设置处理程序，忽略此帧")
            return
        }
        
        // 从样本缓冲区获取图像
        guard let imageBuffer = sampleBuffer.imageBuffer else {
            print("【错误】无法从样本缓冲区获取图像")
            return
        }
        
        // 创建 CIImage
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // 创建 CGImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("【错误】无法创建CGImage")
            return
        }
        
        // 打印截图信息
        print("【ScreenCaptureStreamOutput】成功捕获屏幕截图 - \(Date().formatted(date: .abbreviated, time: .standard))")
        print("【ScreenCaptureStreamOutput】图像尺寸: \(cgImage.width) x \(cgImage.height)")
        
        // 调用处理程序
        captureHandler(cgImage)
    }
    
    // 重置帧计数
    func resetFrameCount() {
        frameCount = 0
        print("【ScreenCaptureStreamOutput】帧计数已重置")
    }
}
