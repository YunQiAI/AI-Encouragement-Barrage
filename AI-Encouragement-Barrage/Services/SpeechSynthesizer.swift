//
//  SpeechSynthesizer.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import AVFoundation

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
            self.isSiriVoice = voice.identifier.contains("com.apple.voice.siri")
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(voice.identifier)
        }
        
        static func == (lhs: VoiceInfo, rhs: VoiceInfo) -> Bool {
            return lhs.voice.identifier == rhs.voice.identifier
        }
    }
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setDefaultSiriVoice()
    }
    
    // Set default Siri voice
    private func setDefaultSiriVoice() {
        // Try to find Chinese Siri voice first
        if let siriVoice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.siri.female.zh-CN") {
            selectedVoiceIdentifier = siriVoice.identifier
            return
        }
        
        // Fallback to any Siri voice
        if let siriVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { 
            $0.identifier.contains("com.apple.voice.siri")
        }) {
            selectedVoiceIdentifier = siriVoice.identifier
            return
        }
        
        // Fallback to system default voice
        selectedVoiceIdentifier = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())?.identifier
    }
    
    // Get all available Siri voices
    func getAvailableSiriVoices() -> [VoiceInfo] {
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.identifier.contains("com.apple.voice.siri") }
            .map { VoiceInfo(voice: $0) }
    }
    
    // Set voice by identifier
    func setVoice(identifier: String) {
        selectedVoiceIdentifier = identifier
    }
    
    // Get current voice identifier
    func getCurrentVoiceIdentifier() -> String {
        return selectedVoiceIdentifier ?? ""
    }
    
    // Speak text with optional completion handler
    func speak(text: String, completion: (() -> Void)? = nil) {
        onSpeechCompleted = completion
        messageQueue.append(text)
        
        if !isSpeaking {
            speakNextMessage()
        }
    }
    
    // Speak next message in queue
    private func speakNextMessage() {
        guard !messageQueue.isEmpty, !isSpeaking else { return }
        
        let text = messageQueue.removeFirst()
        let utterance = AVSpeechUtterance(string: text)
        
        if let voiceId = selectedVoiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        } else {
            setDefaultSiriVoice()
            if let voiceId = selectedVoiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
                utterance.voice = voice
            }
        }
        
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    // Stop speaking
    func stop() {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
        messageQueue.removeAll()
        onSpeechCompleted = nil
    }
    
    // AVSpeechSynthesizerDelegate methods
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        if let completion = onSpeechCompleted {
            DispatchQueue.main.async {
                completion()
            }
        }
        DispatchQueue.main.async {
            self.speakNextMessage()
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
