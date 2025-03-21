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
    case lmStudio // 本地LM Studio
    case openRouter // OpenRouter API
    
    /// 获取每个提供者的显示名称
    var displayName: String {
        switch self {
        case .mock:
            return "模拟数据"
        case .ollama:
            return "本地 Ollama"
        case .lmStudio:
            return "本地 LM Studio"
        case .openRouter:
            return "OpenRouter API"
        }
    }
    
    /// 获取每个提供者的默认模型名称
    var defaultModel: String {
        switch self {
        case .mock:
            return "mock"
        case .ollama:
            return "gemma:2b"
        case .lmStudio:
            return "default"
        case .openRouter:
            return "openai/gpt-3.5-turbo"
        }
    }
    
    /// 获取每个提供者的API基础URL
    var baseURL: String {
        switch self {
        case .mock:
            return ""
        case .ollama:
            return "http://localhost:11434/api/chat"
        case .lmStudio:
            return "http://localhost:1234/v1/chat/completions"
        case .openRouter:
            return "https://openrouter.ai/api/v1/chat/completions"
        }
    }
    
    /// 是否需要API密钥
    var requiresAPIKey: Bool {
        switch self {
        case .mock, .ollama, .lmStudio:
            return false
        case .openRouter:
            return true
        }
    }
    
    /// 获取模型选择提示
    var modelPlaceholder: String {
        switch self {
        case .mock:
            return "模拟模型"
        case .ollama:
            return "例如: gemma:2b, llama3:8b"
        case .lmStudio:
            return "使用LM Studio中加载的模型"
        case .openRouter:
            return "例如: openai/gpt-3.5-turbo"
        }
    }
}
