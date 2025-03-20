//
//  SettingsView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]
    @State private var settings: AppSettings
    @State private var showSaveMessage: Bool = false
    
    // Custom test voice text
    @Binding var testVoiceText: String
    @Binding var showTestVoicePopup: Bool
    
    // Access to app state for testing barrages
    @EnvironmentObject private var appState: AppState
    
    init(testVoiceText: Binding<String>, showTestVoicePopup: Binding<Bool>) {
        // Default settings
        let defaultSettings = AppSettings()
        _settings = State(initialValue: defaultSettings)
        
        // Custom test voice text
        _testVoiceText = testVoiceText
        _showTestVoicePopup = showTestVoicePopup
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("AI Encouragement Barrage Settings")
                    .font(.title)
                    .padding(.bottom, 10)
                
                // API settings
                APISettingsView(settings: $settings)
                
                // Screen capture settings
                ScreenCaptureSettingsView(settings: $settings)
                
                // Barrage settings
                BarrageSettingsView(settings: $settings, appState: appState)
                
                // Voice settings
                VoiceSettingsView(
                    settings: $settings,
                    testVoiceText: $testVoiceText,
                    showTestVoicePopup: $showTestVoicePopup
                )
                
                // Action buttons
                HStack {
                    Button("Restore Defaults") {
                        resetToDefault()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Save Settings") {
                        saveSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 10)
                
                if showSaveMessage {
                    Text("Settings Saved")
                        .foregroundColor(.green)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 400, height: 700) // Increased height to accommodate new settings
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        if let existingSettings = appSettings.first {
            settings = existingSettings
        } else {
            // If no settings exist, create a new one and save
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            settings = newSettings
        }
    }
    
    private func saveSettings() {
        if let existingSettings = appSettings.first {
            // Update all settings from our state
            existingSettings.captureInterval = settings.captureInterval
            existingSettings.barrageSpeed = settings.barrageSpeed
            existingSettings.speechEnabled = settings.speechEnabled
            existingSettings.voiceIdentifier = settings.voiceIdentifier
            existingSettings.barrageDirection = settings.barrageDirection
            existingSettings.barrageTravelRange = settings.barrageTravelRange
            existingSettings.apiProvider = settings.apiProvider
            existingSettings.apiModelName = settings.apiModelName
            existingSettings.apiKey = settings.apiKey
            existingSettings.ollamaServerAddress = settings.ollamaServerAddress
            existingSettings.ollamaServerPort = settings.ollamaServerPort
            existingSettings.useLocalOllama = settings.useLocalOllama
            existingSettings.ollamaModelName = settings.ollamaModelName
            existingSettings.ollamaAPIKey = settings.ollamaAPIKey
            existingSettings.azureEndpoint = settings.azureEndpoint
            existingSettings.azureDeploymentName = settings.azureDeploymentName
            existingSettings.azureAPIVersion = settings.azureAPIVersion
        } else {
            modelContext.insert(settings)
        }
        
        do {
            try modelContext.save()
            showSaveMessage = true
            
            // Hide save message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showSaveMessage = false
            }
            
            // Notify ContentView to update services with these settings
            NotificationCenter.default.post(
                name: NSNotification.Name("TemporarySettingsChanged"),
                object: nil,
                userInfo: ["settings": settings]
            )
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    private func resetToDefault() {
        settings = AppSettings()
    }
}

#Preview {
    SettingsView(
        testVoiceText: .constant("测试文本"),
        showTestVoicePopup: .constant(false)
    )
    .modelContainer(for: [AppSettings.self], inMemory: true)
    .environmentObject(AppState())
}
