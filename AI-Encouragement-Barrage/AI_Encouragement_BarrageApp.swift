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
    // Register AppDelegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Use lazy loading to ensure initialization order is correct
    @StateObject private var appState = AppState()
    
    // Create Logger for logging application lifecycle events
    private let logger = Logger(subsystem: "com.example.AI-Encouragement-Barrage", category: "AppLifecycle")
    
    // Create explicit model container for SwiftData
    private let modelContainer: ModelContainer
    
    init() {
        // Check if database reset is needed
        let shouldResetDatabase = UserDefaults.standard.bool(forKey: "resetDatabase")
        
        // If database reset is needed, try to delete existing database file
        if shouldResetDatabase {
            logger.debug("Attempting to reset database")
            if let dbURL = Self.getDatabaseURL() {
                try? FileManager.default.removeItem(at: dbURL)
                logger.debug("Deleted database file: \(dbURL.path)")
            }
            UserDefaults.standard.set(false, forKey: "resetDatabase")
        }
        
        // Create model schema
        let schema = Schema([
            AppSettings.self,
            EncouragementMessage.self,
            ChatMessage.self  // Add ChatMessage model
        ])
        
        // Try to create model container
        do {
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            logger.debug("SwiftData model container initialized successfully")
        } catch {
            // If failed, try using in-memory storage
            logger.error("SwiftData model container creation failed, falling back to in-memory storage: \(error.localizedDescription)")
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            modelContainer = try! ModelContainer(for: schema, configurations: [fallbackConfiguration])
            
            // Show error notification
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Database initialization failed"
                alert.informativeText = "The application will run in memory-only mode. Data will be lost when the application is closed. Please try resetting the database or contact the developer."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    
    // Get database file URL - static method, doesn't depend on instance properties
    static func getDatabaseURL() -> URL? {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let bundleID = Bundle.main.bundleIdentifier ?? "com.example.AI-Encouragement-Barrage"
        let appDirURL = appSupportURL.appendingPathComponent(bundleID)
        
        // SwiftData typically stores the database in the "default.store" folder in the application support directory
        let dbDirURL = appDirURL.appendingPathComponent("default.store")
        
        return dbDirURL
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    logger.debug("ContentView loaded")
                }
                .background(WindowAccessor { window in
                    // Set window title and style
                    window.title = "AI Encouragement Barrage"
                    window.titlebarAppearsTransparent = true
                    window.isMovableByWindowBackground = true
                    
                    // Set window size and position
                    if let screen = NSScreen.main {
                        let screenRect = screen.visibleFrame
                        let windowWidth: CGFloat = 800
                        let windowHeight: CGFloat = 600
                        let windowX = screenRect.midX - windowWidth / 2
                        let windowY = screenRect.midY - windowHeight / 2
                        window.setFrame(NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight), display: true)
                    }
                    
                    // Explicitly make the window visible and key
                    window.makeKeyAndOrderFront(nil)
                    
                    // Store reference to the main window in AppDelegate
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.mainWindow = window
                    }
                })
        }
        .windowStyle(.titleBar) // Show title bar
        .modelContainer(modelContainer)
        .commands {
            // Add standard command menus
            CommandGroup(replacing: .appInfo) {
                Button("About AI Encouragement Barrage") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
            }
            
            // Add developer menu (only in development phase)
            #if DEBUG
            CommandGroup(after: .appInfo) {
                Button("Reset Database") {
                    UserDefaults.standard.set(true, forKey: "resetDatabase")
                    let alert = NSAlert()
                    alert.messageText = "Database will be reset on next launch"
                    alert.informativeText = "Please restart the application to complete database reset"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "Restart Now")
                    alert.addButton(withTitle: "Restart Later")
                    
                    let response = alert.runModal()
                    if response == .alertFirstButtonReturn {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            #endif
            
            CommandGroup(replacing: .newItem) { }  // Remove "New" menu item
        }
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
