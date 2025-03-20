//
//  AppState.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import SwiftUI

class AppState: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var isProcessing: Bool = false
    @Published var lastEncouragement: String = ""
    @Published var lastCaptureTime: Date? = nil
    @Published var shouldTestBarrages: Bool = false
    @Published var barrageService: BarrageService?
    
    func toggleRunning() {
        isRunning.toggle()
    }
    
    func setProcessing(_ isProcessing: Bool) {
        self.isProcessing = isProcessing
    }
    
    func updateLastEncouragement(_ text: String) {
        self.lastEncouragement = text
        self.lastCaptureTime = Date()
    }
    
    func triggerTestBarrages() {
        shouldTestBarrages = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldTestBarrages = false
        }
    }
}