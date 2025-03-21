//
//  AI_Encouragement_BarrageApp.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import SwiftUI
import SwiftData
import OSLog
import Foundation
import AppKit

// Create an AppDelegate to handle application lifecycle events
class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set activation policy to regular to show dock icon and menu bar
        NSApp.setActivationPolicy(.regular)
        
        // Ensure the app is activated and visible
        NSApp.activate(ignoringOtherApps: true)
        
        // Make sure the main window is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let window = NSApp.windows.first {
                self.mainWindow = window
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    // Handle reopen event (when clicking on dock icon)
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // If no visible windows, show the main window
            if let window = mainWindow ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
}

@main
struct AI_Encouragement_BarrageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .background(WindowAccessor { window in
                    // 设置窗口标题和样式
                    window.title = "AI 弹幕助手"
                    window.titlebarAppearsTransparent = true
                    window.isMovableByWindowBackground = true
                    
                    // 设置窗口大小和位置
                    if let screen = NSScreen.main {
                        let screenRect = screen.visibleFrame
                        let windowWidth: CGFloat = 400
                        let windowHeight: CGFloat = 250
                        let windowX = screenRect.midX - windowWidth / 2
                        let windowY = screenRect.midY - windowHeight / 2
                        window.setFrame(NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight), display: true)
                    }
                    
                    window.makeKeyAndOrderFront(nil)
                    
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.mainWindow = window
                    }
                })
        }
        .windowStyle(.titleBar)
    }
}

// Helper view for accessing and modifying SwiftUI window
struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.callback(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
