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
    
    // 测试结果
    @Published var testResult: String = ""
    @Published var isTesting: Bool = false
    
    init(
        apiProvider: String = "ollama",
        apiModelName: String = "gemma:2b",
        apiKey: String = "",
        barrageSpeed: Double = 100.0,
        barrageDirection: String = "rightToLeft"
    ) {
        // 从UserDefaults加载设置
        self.apiProvider = UserDefaults.standard.string(forKey: "apiProvider") ?? apiProvider
        self.apiModelName = UserDefaults.standard.string(forKey: "apiModelName") ?? apiModelName
        self.apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? apiKey
        self.barrageSpeed = UserDefaults.standard.double(forKey: "barrageSpeed") > 0 ? UserDefaults.standard.double(forKey: "barrageSpeed") : barrageSpeed
        self.barrageDirection = UserDefaults.standard.string(forKey: "barrageDirection") ?? barrageDirection
    }
    
    // 保存设置到UserDefaults
    private func saveSettings() {
        UserDefaults.standard.set(apiProvider, forKey: "apiProvider")
        UserDefaults.standard.set(apiModelName, forKey: "apiModelName")
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
        UserDefaults.standard.set(barrageSpeed, forKey: "barrageSpeed")
        UserDefaults.standard.set(barrageDirection, forKey: "barrageDirection")
    }
    
    // 获取有效的API提供者
    var effectiveAPIProvider: APIProvider {
        return APIProvider(rawValue: apiProvider) ?? .ollama
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
}
