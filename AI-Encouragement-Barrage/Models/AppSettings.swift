//
//  AppSettings.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    // API Settings
    @Published var apiProvider: String {
        didSet {
            saveSettings()
            // 当API提供者改变时，更新模型名称为默认值
            if let provider = APIProvider(rawValue: apiProvider) {
                apiModelName = provider.defaultModel
            }
        }
    }
    
    @Published var apiModelName: String {
        didSet {
            saveSettings()
        }
    }
    
    @Published var apiKey: String {
        didSet {
            saveSettings()
        }
    }
    
    // 弹幕设置
    @Published var barrageSpeed: Double {
        didSet {
            saveSettings()
        }
    }
    
    @Published var barrageDirection: String {
        didSet {
            saveSettings()
        }
    }
    
    // 语音设置
    @Published var speechEnabled: Bool {
        didSet {
            saveSettings()
        }
    }
    
    // 提示词模板
    @Published var promptTemplate: String {
        didSet {
            saveSettings()
        }
    }
    
    // 测试结果
    @Published var testResult: String = ""
    @Published var isTesting: Bool = false
    
    init(
        apiProvider: String = "openRouter",
        apiModelName: String = "deepseek/deepseek-chat:free",
        apiKey: String = "",
        barrageSpeed: Double = 100.0,
        barrageDirection: String = "rightToLeft",
        speechEnabled: Bool = true,
        promptTemplate: String = "你是一个桌面助手。请根据用户的输入生成10-15条积极、鼓励的句子。每个句子应该是完整的，包含标点符号。\n\n用户输入: {input}\n\n请用不同的表达方式生成鼓励性的句子，确保句子多样化且与用户输入相关。"
    ) {
        // 从UserDefaults加载设置
        self.apiProvider = UserDefaults.standard.string(forKey: "apiProvider") ?? apiProvider
        self.apiModelName = UserDefaults.standard.string(forKey: "apiModelName") ?? apiModelName
        self.apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? apiKey
        self.barrageSpeed = UserDefaults.standard.double(forKey: "barrageSpeed") > 0 ? UserDefaults.standard.double(forKey: "barrageSpeed") : barrageSpeed
        self.barrageDirection = UserDefaults.standard.string(forKey: "barrageDirection") ?? barrageDirection
        self.speechEnabled = UserDefaults.standard.object(forKey: "speechEnabled") != nil ? UserDefaults.standard.bool(forKey: "speechEnabled") : speechEnabled
        self.promptTemplate = UserDefaults.standard.string(forKey: "promptTemplate") ?? promptTemplate
    }
    
    // 保存设置到UserDefaults
    private func saveSettings() {
        UserDefaults.standard.set(apiProvider, forKey: "apiProvider")
        UserDefaults.standard.set(apiModelName, forKey: "apiModelName")
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        UserDefaults.standard.set(barrageSpeed, forKey: "barrageSpeed")
        UserDefaults.standard.set(barrageDirection, forKey: "barrageDirection")
        UserDefaults.standard.set(speechEnabled, forKey: "speechEnabled")
        UserDefaults.standard.set(promptTemplate, forKey: "promptTemplate")
    }
    
    // 获取有效的API提供者
    var effectiveAPIProvider: APIProvider {
        return APIProvider(rawValue: apiProvider) ?? .openRouter
    }
    
    // 获取有效的API模型名称
    var effectiveAPIModelName: String {
        return apiModelName
    }
    
    // 获取有效的API密钥
    var effectiveAPIKey: String {
        return apiKey
    }
    
    // 当前API提供者是否需要API密钥
    var currentProviderRequiresAPIKey: Bool {
        return effectiveAPIProvider.requiresAPIKey
    }
    
    // 获取格式化的提示词（替换{input}占位符）
    func getFormattedPrompt(input: String) -> String {
        return promptTemplate.replacingOccurrences(of: "{input}", with: input)
    }
}
