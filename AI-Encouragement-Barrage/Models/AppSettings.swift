//
//  AppSettings.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation

class AppSettings: ObservableObject {
    // API Settings
    @Published var apiProvider: String
    @Published var apiModelName: String
    @Published var apiKey: String
    
    // 弹幕设置
    @Published var barrageSpeed: Double
    @Published var barrageDirection: String
    
    init(
        apiProvider: String = "ollama",
        apiModelName: String = "gemma:2b",
        apiKey: String = "",
        barrageSpeed: Double = 100.0,
        barrageDirection: String = "rightToLeft"
    ) {
        self.apiProvider = apiProvider
        self.apiModelName = apiModelName
        self.apiKey = apiKey
        self.barrageSpeed = barrageSpeed
        self.barrageDirection = barrageDirection
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
}
