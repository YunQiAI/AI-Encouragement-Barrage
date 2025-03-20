//
//  TestVoiceView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import SwiftUI

struct TestVoiceView: View {
    @Binding var testVoiceText: String
    @Binding var showTestVoicePopup: Bool
    @Binding var settings: AppSettings
    
    @State private var speechSynthesizer = SpeechSynthesizer()
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("测试语音")
                .font(.headline)
            
            TextField("输入要测试的文本", text: $testVoiceText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
            
            // 播放按钮
            Button(action: {
                testCustomText()
                isPlaying = true
                
                // 3秒后重置播放状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    isPlaying = false
                }
            }) {
                HStack {
                    Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 20))
                    Text(isPlaying ? "正在播放..." : "播放测试")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isPlaying ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(testVoiceText.isEmpty)
            
            // 预设文本按钮
            VStack(alignment: .leading, spacing: 10) {
                Text("预设文本:")
                    .font(.subheadline)
                
                HStack {
                    Button("我们很棒，不是吗？") {
                        testVoiceText = "我们很棒，不是吗？"
                    }
                    .buttonStyle(.bordered)
                    
                    Button("继续加油，你做得很好！") {
                        testVoiceText = "继续加油，你做得很好！"
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    Button("这个代码写得真漂亮！") {
                        testVoiceText = "这个代码写得真漂亮！"
                    }
                    .buttonStyle(.bordered)
                    
                    Button("你的进步令人印象深刻！") {
                        testVoiceText = "你的进步令人印象深刻！"
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.top, 10)
            
            Spacer()
            
            // 当前选择的语音信息
            if let voiceId = settings.voiceIdentifier {
                HStack {
                    Text("当前语音:")
                        .font(.caption)
                    
                    Spacer()
                    
                    // 播放当前语音示例
                    Button(action: {
                        speechSynthesizer.speakSample(voiceIdentifier: voiceId)
                    }) {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 5)
            }
            
            Button("关闭") {
                showTestVoicePopup = false
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 10)
        }
        .padding()
        .frame(width: 400, height: 350)
    }
    
    // Test custom text with voice
    private func testCustomText() {
        guard !testVoiceText.isEmpty else { return }
        
        let tempSynthesizer = SpeechSynthesizer()
        
        // Use settings voice if available
        if let voiceId = settings.voiceIdentifier {
            tempSynthesizer.setVoice(identifier: voiceId)
        }
        
        tempSynthesizer.speak(text: testVoiceText)
    }
}

struct TestVoiceView_Previews: PreviewProvider {
    static var previews: some View {
        TestVoiceView(
            testVoiceText: .constant("测试文本"),
            showTestVoicePopup: .constant(true),
            settings: .constant(AppSettings())
        )
    }
}