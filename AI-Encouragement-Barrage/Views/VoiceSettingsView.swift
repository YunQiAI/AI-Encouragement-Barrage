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
    @State private var availableSiriVoices: [SpeechSynthesizer.SiriVoiceInfo] = []
    @State private var speechSynthesizer = SpeechSynthesizer()
    @State private var isLoadingVoices: Bool = false
    @State private var showSiriVoiceSelector: Bool = false
    @State private var searchText: String = ""
    @State private var filteredVoices: [SpeechSynthesizer.SiriVoiceInfo] = []
    
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
                // Initialize voice identifiers from settings
                selectedVoiceIdentifier = settings.voiceIdentifier ?? ""
                
                // Load available Siri voices
                loadSiriVoices()
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
            
            // Show selected Siri voice or default text
            HStack {
                if let selectedVoice = availableSiriVoices.first(where: { $0.identifier == selectedVoiceIdentifier }) {
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
                
                // 添加试听按钮
                if let selectedVoice = availableSiriVoices.first(where: { $0.identifier == selectedVoiceIdentifier }) {
                    Button(action: {
                        speechSynthesizer.speakSample(voiceIdentifier: selectedVoice.identifier)
                    }) {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 5)
                }
                
                Button(action: {
                    // Load Siri voices if not already loaded
                    if availableSiriVoices.isEmpty {
                        loadSiriVoices()
                    }
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
            
            // Test voice button with custom text
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
            
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索语音", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchText) { _, _ in
                        filterVoices()
                    }
            }
            .padding(.horizontal)
            
            // Loading indicator or voice list
            if isLoadingVoices {
                VStack {
                    ProgressView()
                    Text("加载语音中...")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredVoices.isEmpty && !searchText.isEmpty {
                VStack {
                    Text("没有找到匹配的语音")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Siri voice list
                List {
                    ForEach(filteredVoices.isEmpty && searchText.isEmpty ? availableSiriVoices : filteredVoices) { voiceInfo in
                        VStack(alignment: .leading) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(voiceInfo.name)
                                        .font(.headline)
                                    Text(voiceInfo.language)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if voiceInfo.identifier == selectedVoiceIdentifier {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                                
                                // Test button - 点击直接播放示例
                                Button(action: {
                                    speechSynthesizer.speakSample(voiceIdentifier: voiceInfo.identifier)
                                }) {
                                    Image(systemName: "speaker.wave.2")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedVoiceIdentifier = voiceInfo.identifier
                        }
                    }
                }
            }
            
            // Action buttons
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
            isLoadingVoices = true
            loadSiriVoices()
            isLoadingVoices = false
        }
    }
    
    // Filter voices based on search text
    private func filterVoices() {
        if searchText.isEmpty {
            filteredVoices = []
            return
        }
        
        filteredVoices = availableSiriVoices.filter { voiceInfo in
            voiceInfo.name.lowercased().contains(searchText.lowercased()) ||
            voiceInfo.language.lowercased().contains(searchText.lowercased())
        }
    }
    
    // Load available Siri voices
    private func loadSiriVoices() {
        // 首先尝试获取Siri语音
        let siriVoices = speechSynthesizer.getAvailableSiriVoices()
        
        // 如果没有找到Siri语音，获取高质量语音
        if siriVoices.isEmpty {
            availableSiriVoices = speechSynthesizer.getAvailablePremiumVoices()
        } else {
            availableSiriVoices = siriVoices
        }
        
        // 打印所有找到的语音，用于调试
        print("找到 \(availableSiriVoices.count) 个高质量语音:")
        for voice in availableSiriVoices {
            print("- \(voice.name) (\(voice.language)): \(voice.identifier)")
        }
        
        // 如果没有选择语音或者选择的语音不在可用列表中，选择默认语音
        if selectedVoiceIdentifier.isEmpty || !availableSiriVoices.contains(where: { $0.identifier == selectedVoiceIdentifier }) {
            // 尝试找到中文语音
            if let chineseVoice = availableSiriVoices.first(where: { 
                $0.language.starts(with: "zh-") 
            }) {
                selectedVoiceIdentifier = chineseVoice.identifier
            }
            // 如果没有中文语音，使用第一个可用的语音
            else if let firstVoice = availableSiriVoices.first {
                selectedVoiceIdentifier = firstVoice.identifier
            }
        }
    }
    
    // Test a specific voice
    private func testVoice(_ identifier: String) {
        speechSynthesizer.speakSample(voiceIdentifier: identifier)
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