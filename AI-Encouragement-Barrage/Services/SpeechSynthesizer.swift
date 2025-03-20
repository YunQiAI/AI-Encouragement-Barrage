//
//  SpeechSynthesizer.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import AVFoundation

// 使用@unchecked Sendable来避免Swift 6中的Sendable错误
class SpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    private var isSpeaking = false
    private var messageQueue: [String] = []
    private var selectedVoiceIdentifier: String?
    
    // Callback for speech completion
    var onSpeechCompleted: (() -> Void)?
    
    // Voice information structure for UI display
    struct VoiceInfo: Identifiable, Hashable {
        let id = UUID()
        let voice: AVSpeechSynthesisVoice
        let name: String
        let language: String
        let quality: String
        let isSiriVoice: Bool
        
        init(voice: AVSpeechSynthesisVoice) {
            self.voice = voice
            self.name = voice.name
            self.language = Locale.current.localizedString(forIdentifier: voice.language) ?? voice.language
            self.quality = voice.quality == .enhanced ? "Enhanced" : "Default"
            // 更精确地判断是否为Siri语音
            self.isSiriVoice = voice.name.contains("Siri") || 
                              (voice.identifier.contains("com.apple.voice.premium") && 
                               voice.quality == .enhanced)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(voice.identifier)
        }
        
        static func == (lhs: VoiceInfo, rhs: VoiceInfo) -> Bool {
            return lhs.voice.identifier == rhs.voice.identifier
        }
    }
    
    // Siri voice information structure
    struct SiriVoiceInfo: Identifiable {
        let id = UUID()
        let identifier: String
        let name: String
        let language: String
        let voice: AVSpeechSynthesisVoice
        
        static func getAllSiriVoices() -> [SiriVoiceInfo] {
            // 获取所有系统语音
            let allVoices = AVSpeechSynthesisVoice.speechVoices()
            
            // 打印所有语音信息，用于调试
            for voice in allVoices {
                print("Voice: \(voice.name), ID: \(voice.identifier), Language: \(voice.language), Quality: \(voice.quality.rawValue)")
            }
            
            // 筛选真正的Siri语音
            // 1. 名称中包含"Siri"的语音
            // 2. 或者是高质量(enhanced)的premium语音
            return allVoices
                .filter { voice in 
                    voice.name.contains("Siri") || 
                    (voice.identifier.contains("com.apple.voice.premium") && 
                     voice.quality == .enhanced)
                }
                .map { voice in
                    return SiriVoiceInfo(
                        identifier: voice.identifier,
                        name: voice.name,
                        language: Locale.current.localizedString(forIdentifier: voice.language) ?? voice.language,
                        voice: voice
                    )
                }
        }
    }
    
    override init() {
        super.init()
        // Set delegate to handle speech completion
        synthesizer.delegate = self
        
        // 设置默认为中文Siri语音
        findAndSetDefaultSiriVoice()
    }
    
    // 查找并设置默认的Siri语音
    private func findAndSetDefaultSiriVoice() {
        // 首先尝试找中文Siri女声
        if let siriVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { 
            $0.name.contains("Siri") && $0.language.starts(with: "zh-")
        }) {
            selectedVoiceIdentifier = siriVoice.identifier
            return
        }
        
        // 然后尝试任何中文高质量语音
        if let premiumVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { 
            $0.language.starts(with: "zh-") && $0.quality == .enhanced
        }) {
            selectedVoiceIdentifier = premiumVoice.identifier
            return
        }
        
        // 然后尝试任何Siri语音
        if let siriVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { 
            $0.name.contains("Siri")
        }) {
            selectedVoiceIdentifier = siriVoice.identifier
            return
        }
        
        // 最后尝试任何中文语音
        if let chineseVoice = AVSpeechSynthesisVoice.speechVoices().first(where: {
            $0.language.starts(with: "zh-")
        }) {
            selectedVoiceIdentifier = chineseVoice.identifier
            return
        }
        
        // 如果都没有，使用系统默认声音
        selectedVoiceIdentifier = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())?.identifier
    }
    
    // 打印所有可用的语音，用于调试
    func printAllAvailableVoices() {
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            print("\(voice.identifier) - \(voice.name) - \(voice.language) - Quality: \(voice.quality.rawValue)")
        }
    }
    
    // Get all available voices
    func getAvailableVoices() -> [VoiceInfo] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        return voices.map { VoiceInfo(voice: $0) }
    }
    
    // Get all available Siri voices
    func getAvailableSiriVoices() -> [SiriVoiceInfo] {
        return SiriVoiceInfo.getAllSiriVoices()
    }
    
    // Get all available premium voices (if no Siri voices found)
    func getAvailablePremiumVoices() -> [SiriVoiceInfo] {
        let siriVoices = SiriVoiceInfo.getAllSiriVoices()
        if !siriVoices.isEmpty {
            return siriVoices
        }
        
        // 如果没有找到Siri语音，返回所有高质量语音
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.quality == .enhanced }
            .map { voice in
                return SiriVoiceInfo(
                    identifier: voice.identifier,
                    name: voice.name,
                    language: Locale.current.localizedString(forIdentifier: voice.language) ?? voice.language,
                    voice: voice
                )
            }
    }
    
    // Get voices for a specific language
    func getVoicesForLanguage(languageCode: String) -> [VoiceInfo] {
        return getAvailableVoices().filter { $0.voice.language.starts(with: languageCode) }
    }
    
    // Set voice by identifier
    func setVoice(identifier: String) {
        selectedVoiceIdentifier = identifier
    }
    
    // Get current voice identifier
    func getCurrentVoiceIdentifier() -> String {
        return selectedVoiceIdentifier ?? ""
    }
    
    // 直接播放语音示例
    func speakSample(voiceIdentifier: String) {
        let tempSynthesizer = AVSpeechSynthesizer()
        let sampleText: String
        
        // 根据语音的语言选择示例文本
        if let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            if voice.language.starts(with: "zh-") {
                sampleText = "这是语音示例"
            } else if voice.language.starts(with: "ja-") {
                sampleText = "これは音声サンプルです"
            } else if voice.language.starts(with: "de-") {
                sampleText = "Dies ist ein Sprachbeispiel"
            } else if voice.language.starts(with: "fr-") {
                sampleText = "Ceci est un exemple vocal"
            } else if voice.language.starts(with: "es-") {
                sampleText = "Este es un ejemplo de voz"
            } else {
                sampleText = "This is a voice sample"
            }
            
            let utterance = AVSpeechUtterance(string: sampleText)
            utterance.voice = voice
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
            
            tempSynthesizer.speak(utterance)
        }
    }
    
    // Speak text with optional completion handler
    func speak(text: String, completion: (() -> Void)? = nil) {
        // Set completion handler
        onSpeechCompleted = completion
        
        // Add message to queue
        messageQueue.append(text)
        
        // If not currently speaking, start speaking
        if !isSpeaking {
            speakNextMessage()
        }
    }
    
    // Speak next message in queue
    private func speakNextMessage() {
        // If queue is empty or already speaking, return
        if messageQueue.isEmpty || isSpeaking {
            return
        }
        
        // Get next message from queue
        let text = messageQueue.removeFirst()
        
        // Create speech utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Set voice
        if let voiceId = selectedVoiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        } else {
            // 如果没有设置语音或语音无效，尝试重新查找默认语音
            findAndSetDefaultSiriVoice()
            if let voiceId = selectedVoiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
                utterance.voice = voice
            }
        }
        
        // 设置语速和音调
        utterance.rate = 0.5  // 中等语速 (0.1-1.0)
        utterance.pitchMultiplier = 1.0  // 标准音高 (0.5-2.0)
        utterance.volume = 1.0  // 最大音量
        
        // Start speaking
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    // Stop speaking
    func stop() {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
        // Clear message queue
        messageQueue.removeAll()
        // Reset completion handler
        onSpeechCompleted = nil
    }
    
    // Check if currently speaking
    var isCurrentlySpeaking: Bool {
        return isSpeaking
    }
    
    // AVSpeechSynthesizerDelegate methods
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // When finished speaking, set isSpeaking to false
        isSpeaking = false
        
        // Call completion handler if set
        if let completion = onSpeechCompleted {
            DispatchQueue.main.async {
                completion()
            }
        }
        
        // Speak next message if available
        DispatchQueue.main.async {
            self.speakNextMessage()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // When speech is cancelled, set isSpeaking to false
        isSpeaking = false
    }
}
