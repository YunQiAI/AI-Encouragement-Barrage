//
//  ScreenCaptureSettingsView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import SwiftUI

struct ScreenCaptureSettingsView: View {
    @Binding var settings: AppSettings
    
    var body: some View {
        GroupBox(label: Text("Screen Capture Settings").font(.headline)) {
            VStack(alignment: .leading) {
                Text("Capture Interval (seconds): \(Int(settings.captureInterval))")
                Slider(value: $settings.captureInterval, in: 5...120, step: 5) {
                    Text("Capture Interval")
                }
                .padding(.vertical, 5)
                
                Text("Shorter intervals mean more frequent encouragement, but use more resources")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider().padding(.vertical, 5)
                
                // Permission status
                HStack {
                    Image(systemName: checkScreenCapturePermission() ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(checkScreenCapturePermission() ? .green : .orange)
                    
                    Text(checkScreenCapturePermission() ? "Screen capture permission granted" : "Screen capture permission required")
                        .font(.caption)
                    
                    Spacer()
                    
                    if !checkScreenCapturePermission() {
                        Button("Request") {
                            requestScreenCapturePermission()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 5)
            }
            .padding(.vertical, 10)
        }
    }
    
    // Check screen capture permission
    private func checkScreenCapturePermission() -> Bool {
        // This is a simplified check - in a real app, you would use ScreenCaptureManager
        // For preview purposes, we'll just return true
        #if DEBUG
        return true
        #else
        let manager = ScreenCaptureManager(captureInterval: settings.captureInterval)
        return manager.checkScreenCapturePermission()
        #endif
    }
    
    // Request screen capture permission
    private func requestScreenCapturePermission() {
        // This is a simplified request - in a real app, you would use ScreenCaptureManager
        #if DEBUG
        print("Requesting screen capture permission")
        #else
        let manager = ScreenCaptureManager(captureInterval: settings.captureInterval)
        manager.requestScreenCapturePermission()
        #endif
    }
}

struct ScreenCaptureSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenCaptureSettingsView(
            settings: .constant(AppSettings())
        )
        .padding()
    }
}