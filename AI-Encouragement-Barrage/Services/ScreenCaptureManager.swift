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

// 使用@unchecked Sendable来避免Swift 6中的Sendable错误
class ScreenCaptureManager: ObservableObject, @unchecked Sendable {
    private var captureTimer: Timer?
    private var captureInterval: TimeInterval
    private var isCapturing: Bool = false
    private var captureHandler: ((CGImage?) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
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
    }
    
    func setCaptureInterval(_ interval: TimeInterval) {
        self.captureInterval = interval
        
        // 如果正在捕获，重新启动定时器
        if isCapturing, let handler = captureHandler {
            stopCapturing()
            startCapturing(handler: handler)
        }
    }
    
    // 使用CGWindowListCreateImage捕获屏幕
    // 虽然CGWindowListCreateImage在macOS 14.0中被标记为废弃，但我们暂时继续使用它
    // 因为它比ScreenCaptureKit更简单，更容易实现
    @MainActor
    private func captureScreen() {
        // 获取主屏幕尺寸
        guard let screen = NSScreen.main else {
            print("无法获取主屏幕")
            return
        }
        
        let rect = screen.frame
        let captureRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)
        
        // 捕获屏幕内容
        // 使用#available检查是否可以使用更新的API
        #if os(macOS)
        // 我们知道CGWindowListCreateImage在macOS 14.0中被废弃，但暂时继续使用它
        // 在未来版本中，我们应该使用ScreenCaptureKit
        // 使用@available来标记这个方法，表明我们知道它已经被废弃
        @available(macOS, deprecated: 14.0, message: "Using deprecated API temporarily")
        func captureWithDeprecatedAPI() -> CGImage? {
            return CGWindowListCreateImage(captureRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution)
        }
        
        if let windowImage = captureWithDeprecatedAPI() {
            self.captureHandler?(windowImage)
        } else {
            print("无法捕获屏幕内容")
        }
        #endif
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
    func captureScreenNow() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.captureScreen()
        }
    }
}
