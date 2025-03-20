//
//  StatusBarController.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private var appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        // Set status bar icon
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "AI Encouragement Barrage")
        }
        
        // Set up menu
        setupMenu()
    }
    
    // Set up menu
    func setupMenu() {
        let menu = NSMenu()
        
        // Add start/stop menu item
        let toggleItem = NSMenuItem(title: "Start", action: #selector(toggleActive), keyEquivalent: "t")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        // Add test barrage menu item
        let testItem = NSMenuItem(title: "Test Barrages", action: #selector(testBarrages), keyEquivalent: "")
        testItem.target = self
        menu.addItem(testItem)
        
        // Add show main window menu item
        let showWindowItem = NSMenuItem(title: "Show Main Window", action: #selector(showMainWindow), keyEquivalent: "")
        showWindowItem.target = self
        menu.addItem(showWindowItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add quit menu item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Set status bar item's menu
        statusItem.menu = menu
        
        // Update menu state
        updateMenuState()
        
        // Listen for app state changes to update menu
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenuState),
            name: NSNotification.Name("AppStateChanged"),
            object: nil
        )
    }
    
    // Update menu state
    @objc func updateMenuState() {
        if let toggleItem = statusItem.menu?.item(at: 0) {
            toggleItem.title = appState.isRunning ? "Stop" : "Start"
        }
        
        // Update status bar icon
        if let button = statusItem.button {
            if appState.isRunning {
                button.image = NSImage(systemSymbolName: "bubble.left.fill", accessibilityDescription: "AI Encouragement Barrage")
            } else {
                button.image = NSImage(systemSymbolName: "bubble.left", accessibilityDescription: "AI Encouragement Barrage")
            }
        }
    }
    
    // Toggle app active state
    @objc func toggleActive() {
        appState.toggleRunning()
        
        // Send notification to update menu state
        NotificationCenter.default.post(name: NSNotification.Name("AppStateChanged"), object: nil)
    }
    
    // Show main window
    @objc func showMainWindow() {
        // Find the main window and bring it to front
        if let window = NSApp.windows.first(where: { $0.title == "AI Encouragement Barrage" }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    // Quit app
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    // Test barrages
    @objc func testBarrages() {
        appState.triggerTestBarrages()
    }
}