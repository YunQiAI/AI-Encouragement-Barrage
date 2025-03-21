//
//  AppState.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    // 弹幕显示状态
    @Published var isBarrageActive: Bool = false {
        didSet {
            UserDefaults.standard.set(isBarrageActive, forKey: "BarrageActive")
            if isBarrageActive {
                startBarrage()
            } else {
                stopBarrage()
            }
        }
    }
    
    // 当前AI处理状态
    @Published private(set) var isProcessing: Bool = false
    
    // 服务
    private var barrageService: BarrageService?
    private var barrageLibrary: BarrageLibrary?
    private var aiService: AIService?
    
    // 弹幕定时器
    private var barrageTimer: Timer?
    
    // 当前上下文
    @Published var currentContext: String = ""
    
    init() {}
    
    func initialize(barrageService: BarrageService, aiService: AIService) {
        self.barrageService = barrageService
        self.aiService = aiService
        self.barrageLibrary = BarrageLibrary(aiService: aiService)
        
        // 加载保存的状态
        if UserDefaults.standard.object(forKey: "BarrageActive") != nil {
            isBarrageActive = UserDefaults.standard.bool(forKey: "BarrageActive")
        }
    }
    
    // 设置新的上下文并生成弹幕
    func setContext(_ context: String) async {
        guard let barrageLibrary = barrageLibrary else { return }
        
        // 在主线程上更新UI状态
        await MainActor.run {
            currentContext = context
            isProcessing = true
        }
        
        do {
            try await barrageLibrary.setContext(context)
            
            // 在主线程上更新UI状态和启动弹幕
            await MainActor.run {
                isProcessing = false
                if isBarrageActive {
                    startBarrage()
                }
            }
        } catch {
            // 在主线程上更新UI状态
            await MainActor.run {
                isProcessing = false
                print("设置上下文失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 开始显示弹幕
    private func startBarrage() {
        guard let barrageService = barrageService, let barrageLibrary = barrageLibrary else { return }
        
        stopBarrage() // 确保先停止现有的定时器
        
        // 创建新的定时器，每0.8秒随机显示一条弹幕
        barrageTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 使用Task在主线程上执行MainActor隔离的方法
            Task { @MainActor in
                if let barrage = barrageLibrary.getRandomBarrage() {
                    barrageService.showBarrage(text: barrage.text)
                }
            }
        }
    }
    
    // 停止显示弹幕
    private func stopBarrage() {
        barrageTimer?.invalidate()
        barrageTimer = nil
        
        // 确保在主线程上调用clearAllBarrages
        if let service = barrageService {
            service.clearAllBarrages()
        }
    }
    
    // 切换弹幕显示状态
    func toggleBarrage() {
        isBarrageActive.toggle()
        
        // 如果开启弹幕但没有上下文，提示用户设置上下文
        if isBarrageActive && currentContext.isEmpty {
            print("请先设置上下文")
            isBarrageActive = false
        }
    }
    
    deinit {
        // 在deinit中安全地停止定时器
        barrageTimer?.invalidate()
        barrageTimer = nil
    }
}
