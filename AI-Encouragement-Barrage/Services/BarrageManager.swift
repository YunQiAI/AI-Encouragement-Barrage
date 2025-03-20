//
//  BarrageManager.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import SwiftUI
import AppKit

// Barrage item
struct BarrageItem: Identifiable {
    let id = UUID()
    let text: String
    var position: CGPoint
    var opacity: Double = 1.0
    var direction: Direction
    var fontSize: CGFloat
    var color: Color
    var isError: Bool = false
    
    enum Direction {
        case leftToRight
        case rightToLeft
        
        static func random() -> Direction {
            return Bool.random() ? .leftToRight : .rightToLeft
        }
        
        static func fromString(_ directionString: String) -> Direction {
            switch directionString {
            case "leftToRight":
                return .leftToRight
            case "rightToLeft":
                return .rightToLeft
            default:
                return .rightToLeft // Default right to left
            }
        }
    }
    
    static func create(text: String, screenSize: CGSize, direction: Direction, isError: Bool = false) -> BarrageItem {
        let startX: CGFloat
        
        if direction == .leftToRight {
            startX = -200 // Start from outside left
        } else {
            startX = screenSize.width + 200 // Start from outside right
        }
        
        // Random Y position to avoid overlap
        // Use full screen height for Y position
        let y = CGFloat.random(in: 50...(screenSize.height - 100))
        
        // Random font size
        let fontSize = CGFloat.random(in: 18...28)
        
        // Color settings
        let color: Color
        if isError {
            color = Color.red // Red for error messages
        } else {
            // Random color with high brightness and saturation
            let hue = Double.random(in: 0...1)
            color = Color(hue: hue, saturation: 0.7, brightness: 0.9)
        }
        
        return BarrageItem(
            text: text,
            position: CGPoint(x: startX, y: y),
            direction: direction,
            fontSize: fontSize,
            color: color,
            isError: isError
        )
    }
}

// Barrage manager
class BarrageManager: ObservableObject {
    @Published var activeBarrages: [BarrageItem] = []
    private var speed: Double = 1.0
    private var timer: Timer?
    private var screenSize: CGSize
    private var directionSetting: String = "rightToLeft" // Default right to left
    private var travelRange: Double = 1.0 // Default full screen
    
    init(screenSize: CGSize) {
        self.screenSize = screenSize
        startAnimationTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // Set barrage direction
    func setDirection(_ direction: String) {
        self.directionSetting = direction
    }
    
    // Set barrage travel range (horizontal movement range)
    func setTravelRange(_ range: Double) {
        self.travelRange = range
    }
    
    // Add new barrage
    func addBarrage(text: String, isError: Bool = false) {
        // Determine direction based on settings
        let direction: BarrageItem.Direction
        
        switch directionSetting {
        case "leftToRight":
            direction = .leftToRight
        case "rightToLeft":
            direction = .rightToLeft
        case "bidirectional":
            // Random direction in bidirectional mode
            direction = Bool.random() ? .leftToRight : .rightToLeft
        default:
            direction = .rightToLeft // Default right to left
        }
        
        let newBarrage = BarrageItem.create(
            text: text,
            screenSize: screenSize,
            direction: direction,
            isError: isError
        )
        
        DispatchQueue.main.async {
            self.activeBarrages.append(newBarrage)
            
            // Remove barrage after it completes its journey
            // The time depends on the travel range and speed
            let travelTime = (self.screenSize.width * self.travelRange + 400) / (self.speed * 3.0) * 0.03
            DispatchQueue.main.asyncAfter(deadline: .now() + travelTime) {
                self.activeBarrages.removeAll { $0.id == newBarrage.id }
            }
        }
    }
    
    // Clear all barrages
    func clearAllBarrages() {
        activeBarrages.removeAll()
    }
    
    // Set barrage speed
    func setSpeed(_ speed: Double) {
        self.speed = speed
    }
    
    // Update screen size
    func updateScreenSize(_ size: CGSize) {
        self.screenSize = size
    }
    
    // Start animation timer
    private func startAnimationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1/30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateBarragePositions()
        }
    }
    
    // Update barrage positions
    private func updateBarragePositions() {
        DispatchQueue.main.async {
            for i in 0..<self.activeBarrages.count {
                var barrage = self.activeBarrages[i]
                
                // Update position based on direction
                let moveDistance = self.speed * 3.0 // Base movement speed
                
                if barrage.direction == .leftToRight {
                    barrage.position.x += moveDistance
                    
                    // Calculate the total travel distance based on travelRange
                    let totalTravelDistance = self.screenSize.width * self.travelRange
                    
                    // Start fading out when approaching the end of travel distance
                    if barrage.position.x > totalTravelDistance {
                        // Calculate fade based on distance past the travel limit
                        let distancePastLimit = barrage.position.x - totalTravelDistance
                        let fadeRate = min(distancePastLimit / 200.0, 0.05) // Gradual fade out
                        barrage.opacity -= fadeRate
                    }
                } else {
                    barrage.position.x -= moveDistance
                    
                    // Calculate the starting point for right-to-left barrages
                    let startPoint = self.screenSize.width * (1.0 - self.travelRange)
                    
                    // Start fading out when approaching the end of travel distance
                    if barrage.position.x < startPoint {
                        // Calculate fade based on distance past the travel limit
                        let distancePastLimit = startPoint - barrage.position.x
                        let fadeRate = min(distancePastLimit / 200.0, 0.05) // Gradual fade out
                        barrage.opacity -= fadeRate
                    }
                }
                
                self.activeBarrages[i] = barrage
            }
            
            // Remove completely transparent barrages
            self.activeBarrages.removeAll { $0.opacity <= 0 }
        }
    }
}