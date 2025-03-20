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
    let isError: Bool
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
            enqueue(QueuedBarrage(
                text: text,
                isError: isError,
                shouldSpeak: shouldSpeak,
                completion: nil
            ))
        }
    }
    
    private func processNextIfNeeded() {
        guard !isProcessing, !queue.isEmpty else { return }
        
        isProcessing = true
        let barrage = queue.removeFirst()
        
        // Show barrage
        barrageWindow?.addBarrage(text: barrage.text, isError: barrage.isError)
        
        // Handle speech if enabled and requested
        if speechEnabled && barrage.shouldSpeak, let synthesizer = speechSynthesizer {
            synthesizer.speak(text: barrage.text) {
                self.finishCurrentBarrage(completion: barrage.completion)
            }
        } else {
            // If no speech, wait for a fixed duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.finishCurrentBarrage(completion: barrage.completion)
            }
        }
    }
    
    private func finishCurrentBarrage(completion: (() -> Void)?) {
        completion?()
        isProcessing = false
        
        // Process next barrage after a short delay
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