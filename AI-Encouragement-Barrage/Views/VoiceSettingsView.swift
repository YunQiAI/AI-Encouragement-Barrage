//
//  VoiceSettingsView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import SwiftUI
import AVFoundation

struct VoiceSettingsView: View {
    @Binding var settings: AppSettings
    @Binding var testVoiceText: String
    @Binding var showTestVoicePopup: Bool
    
    @State private var selectedVoiceIdentifier: String = ""
    @State private var availableSiriVoices: [SpeechSynthesizer.VoiceInfo] = []
    @State private var isLoadingVoices: Bool = false
    @State private var showSiriVoiceSelector: Bool = false
    
    var body: some View {
        GroupBox(label: Text("语音设置").font(.headline)) {
            VStack(alignment: .leading) {
                Toggle("启用语音朗读", isOn: $settings.speechEnabled)
                    .padding(.vertical, 5)
                
                Divider().padding(.vertical, 5)
                
                // Siri voice selection
                siriVoiceSelectionView
            }
            .padding(.vertical, 10)
            .onAppear {
                selectedVoiceIdentifier = settings.voiceIdentifier ?? ""
            }
            .onChange(of: selectedVoiceIdentifier) { _, newValue in
                settings.voiceIdentifier = newValue.isEmpty ? nil : newValue
            }
            .sheet(isPresented: $showSiriVoiceSelector) {
                siriVoiceSelectorView
                    .frame(width: 500, height: 500)
            }
        }
    }
    
    // Siri voice selection view
    private var siriVoiceSelectionView: some View {
        VStack(alignment: .leading) {
            Text("高质量语音:")
            
            HStack {
                if let selectedVoice = availableSiriVoices.first(where: { $0.voice.identifier == selectedVoiceIdentifier }) {
                    VStack(alignment: .leading) {
                        Text(selectedVoice.name)
                            .font(.headline)
                        Text(selectedVoice.language)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("默认中文语音")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    loadSiriVoices()
                    showSiriVoiceSelector.toggle()
                }) {
                    Text("更改")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color(.textBackgroundColor).opacity(0.1))
            .cornerRadius(8)
            
            // Test voice button
            Button(action: {
                showTestVoicePopup = true
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("测试语音")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 5)
        }
        .padding(.vertical, 5)
    }
    
    // Siri voice selector view
    var siriVoiceSelectorView: some View {
        VStack {
            Text("选择语音")
                .font(.headline)
                .padding()
            
            if isLoadingVoices {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(availableSiriVoices) { voiceInfo in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(voiceInfo.name)
                                .font(.headline)
                            Text(voiceInfo.language)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if voiceInfo.voice.identifier == selectedVoiceIdentifier {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedVoiceIdentifier = voiceInfo.voice.identifier
                    }
                }
            }
            
            HStack {
                Button("取消") {
                    showSiriVoiceSelector = false
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("选择") {
                    showSiriVoiceSelector = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onAppear {
            loadSiriVoices()
        }
    }
    
    // Load Siri voices
    private func loadSiriVoices() {
        isLoadingVoices = true
        let synthesizer = SpeechSynthesizer()
        availableSiriVoices = synthesizer.getAvailableSiriVoices()
        isLoadingVoices = false
    }
}

struct VoiceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceSettingsView(
            settings: .constant(AppSettings()),
            testVoiceText: .constant("测试文本"),
            showTestVoicePopup: .constant(false)
        )
        .padding()
    }
}