//
//  SpeechService.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import AVFoundation

/// 语音服务 - 负责文本转语音
class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    /// 语音合成器
    private let synthesizer = AVSpeechSynthesizer()
    
    /// 是否正在播放
    private(set) var isSpeaking: Bool = false
    
    /// 完成回调
    private var completionHandler: (() -> Void)?
    
    /// 初始化
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    /// 播放文本
    /// - Parameters:
    ///   - text: 要播放的文本
    ///   - completion: 播放完成后的回调
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        // 如果已经在播放，则停止当前播放
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // 保存完成回调
        self.completionHandler = completion
        
        // 创建语音合成请求
        let utterance = AVSpeechUtterance(string: text)
        
        // 设置语音属性
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN") // 使用中文
        utterance.rate = 0.5 // 语速 (0.0 - 1.0)
        utterance.pitchMultiplier = 1.0 // 音调
        utterance.volume = 1.0 // 音量
        
        // 开始播放
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    /// 停止播放
    func stopSpeaking() {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    /// 语音播放完成
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        
        // 调用完成回调
        if let completion = completionHandler {
            DispatchQueue.main.async {
                completion()
            }
            completionHandler = nil
        }
    }
    
    /// 语音播放取消
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        
        // 调用完成回调
        if let completion = completionHandler {
            DispatchQueue.main.async {
                completion()
            }
            completionHandler = nil
        }
    }
}