//
//  APIProvider.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation

/// API提供者枚举
enum APIProvider: String, CaseIterable {
    case mock // 使用模拟数据
    case ollama // 本地Ollama
    
    /// 获取每个提供者的显示名称
    var displayName: String {
        switch self {
        case .mock:
            return "模拟数据"
        case .ollama:
            return "本地 Ollama"
        }
    }
    
    /// 获取每个提供者的默认模型名称
    var defaultModel: String {
        switch self {
        case .mock:
            return "mock"
        case .ollama:
            return "gemma:2b"
        }
    }
}
