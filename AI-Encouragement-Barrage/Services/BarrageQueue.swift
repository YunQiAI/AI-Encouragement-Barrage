//
//  BarrageQueue.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import SwiftUI

struct QueuedBarrage {
    let text: String
    var shouldSpeak: Bool
    let completion: (() -> Void)?
}

class BarrageQueue: ObservableObject {
    private var queue: [QueuedBarrage] = []
    private var isProcessing = false
    
    private var barrageWindow: BarrageOverlayWindow?
    private var speechSynthesizer: SpeechSynthesizer?
    private var speechEnabled: Bool = false
    
    init(barrageWindow: BarrageOverlayWindow?, speechSynthesizer: SpeechSynthesizer?) {
        self.barrageWindow = barrageWindow
        self.speechSynthesizer = speechSynthesizer
    }
    
    func setSpeechEnabled(_ enabled: Bool) {
        self.speechEnabled = enabled
    }
    
    func enqueue(_ barrage: QueuedBarrage) {
        queue.append(barrage)
        processNextIfNeeded()
    }
    
    func enqueueMultiple(_ texts: [String], shouldSpeak: Bool = true, isError: Bool = false) {
        for text in texts {
            let type: BarrageItem.BarrageType = isError ? .error : .normal
            enqueue(QueuedBarrage(
                text: text,
                shouldSpeak: shouldSpeak,
                completion: nil
            ))
            
            // 使用新的API添加弹幕
            barrageWindow?.addBarrage(text: text, type: type)
        }
    }
    
    private func processNextIfNeeded() {
        guard !isProcessing, !queue.isEmpty else { return }
        
        isProcessing = true
        let barrage = queue.removeFirst()
        
        // 处理语音（如果启用并请求）
        if speechEnabled && barrage.shouldSpeak, let synthesizer = speechSynthesizer {
            synthesizer.speak(text: barrage.text) {
                self.finishCurrentBarrage(completion: barrage.completion)
            }
        } else {
            // 如果没有语音，等待固定时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.finishCurrentBarrage(completion: barrage.completion)
            }
        }
    }
    
    private func finishCurrentBarrage(completion: (() -> Void)?) {
        completion?()
        isProcessing = false
        
        // 处理队列中的下一个弹幕（短暂延迟后）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.processNextIfNeeded()
        }
    }
    
    func clear() {
        queue.removeAll()
        isProcessing = false
        speechSynthesizer?.stop()
    }
}