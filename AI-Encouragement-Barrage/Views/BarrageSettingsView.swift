//
//  BarrageSettingsView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import SwiftUI

struct BarrageSettingsView: View {
    @Binding var settings: AppSettings
    var appState: AppState
    
    var body: some View {
        GroupBox(label: Text("Barrage Settings").font(.headline)) {
            VStack(alignment: .leading) {
                Text("Barrage Speed: \(settings.barrageSpeed, specifier: "%.1f")")
                Slider(value: $settings.barrageSpeed, in: 0.5...5.0, step: 0.1)
                
                Text("Higher values make barrages scroll faster")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider().padding(.vertical, 5)
                
                Text("Barrage Direction:")
                Picker("Barrage Direction", selection: $settings.barrageDirection.toUnwrapped(defaultValue: "rightToLeft")) {
                    Text("Right to Left").tag("rightToLeft")
                    Text("Left to Right").tag("leftToRight")
                    Text("Bidirectional").tag("bidirectional")
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 5)
                
                Divider().padding(.vertical, 5)
                
                Text("Barrage Travel Range: \(Int((settings.barrageTravelRange ?? 1.0) * 100))%")
                Slider(value: Binding(
                    get: { settings.barrageTravelRange ?? 1.0 },
                    set: { settings.barrageTravelRange = $0 }
                ), in: 0.3...1.0, step: 0.05)
                
                Text("Adjust the width range of barrages on screen")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider().padding(.vertical, 5)
                
                // Test barrage button
                Button(action: {
                    // Apply current settings before testing
                    applyCurrentSettings()
                    // Trigger test barrages
                    appState.triggerTestBarrages()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Test Barrages")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.top, 5)
            }
            .padding(.vertical, 10)
        }
    }
    
    // Apply current settings without saving to database
    private func applyCurrentSettings() {
        // Create a temporary settings object with current values
        let tempSettings = settings
        
        // Notify ContentView to update services with these settings
        NotificationCenter.default.post(
            name: NSNotification.Name("TemporarySettingsChanged"),
            object: nil,
            userInfo: ["settings": tempSettings]
        )
    }
}

// Extension to handle optional binding
extension Binding where Value == String? {
    func toUnwrapped(defaultValue: String) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

// Extension to handle optional Double binding
extension Binding where Value == Double? {
    func toUnwrapped(defaultValue: Double) -> Binding<Double> {
        Binding<Double>(
            get: { self.wrappedValue ?? defaultValue },
            set: { self.wrappedValue = $0 }
        )
    }
}

struct BarrageSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BarrageSettingsView(
            settings: .constant(AppSettings()),
            appState: AppState()
        )
        .padding()
    }
}