//
//  APIProvider.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation

// API provider types supported by the application
enum APIProvider: String, CaseIterable, Identifiable {
    case ollama = "Ollama API"
    case azure = "Azure OpenAI API"
    case openai = "OpenAI API (未测试)"
    case googleGemini = "Google Gemini API (未测试)"
    case anthropic = "Anthropic API (未测试)"
    case lmStudio = "LM Studio API"
    case deepSeek = "DeepSeek API (未测试)"
    case siliconFlow = "SiliconFlow API (未测试)"
    case xai = "xAI API (未测试)"
    case perplexity = "Perplexity API (未测试)"
    case groq = "Groq API (未测试)"
    case chatGLM = "ChatGLM API (未测试)"
    
    var id: String { self.rawValue }
    
    // Base URL for each provider
    var baseURL: String {
        switch self {
        case .ollama:
            return "http://localhost:8000" // Default local Ollama server
        case .azure:
            // Azure OpenAI API doesn't have a fixed base URL, it's provided by the user
            return "https://RESOURCE_NAME.openai.azure.com" // This is just a placeholder
        case .openai:
            return "https://api.openai.com/v1"
        case .googleGemini:
            return "https://generativelanguage.googleapis.com/v1"
        case .anthropic:
            return "https://api.anthropic.com/v1"
        case .lmStudio:
            return "http://127.0.0.1:1234" // Default local LM Studio server
        case .deepSeek:
            return "https://api.deepseek.com/v1"
        case .siliconFlow:
            return "https://api.siliconflow.com/v1"
        case .xai:
            return "https://api.xai.com/v1"
        case .perplexity:
            return "https://api.perplexity.ai"
        case .groq:
            return "https://api.groq.com/v1"
        case .chatGLM:
            return "https://api.chatglm.cn/v1"
        }
    }
    
    // Default model for each provider
    var defaultModel: String {
        switch self {
        case .ollama:
            return "gemma3:4b"
        case .azure:
            return "gpt-4o" // Default to Azure ChatGPT4o
        case .openai:
            return "gpt-4o"
        case .googleGemini:
            return "gemini-1.5-pro"
        case .anthropic:
            return "claude-3-opus"
        case .lmStudio:
            return "gemma-3-12b-it" // Updated default model for LM Studio
        case .deepSeek:
            return "deepseek-coder"
        case .siliconFlow:
            return "default"
        case .xai:
            return "grok-1"
        case .perplexity:
            return "sonar-medium-online"
        case .groq:
            return "llama3-70b-8192"
        case .chatGLM:
            return "glm-4"
        }
    }
    
    // Whether the provider supports image analysis
    var supportsImages: Bool {
        switch self {
        case .ollama, .azure, .openai, .googleGemini, .anthropic, .lmStudio:
            return true
        default:
            return false
        }
    }
    
    // Whether the provider is tested and confirmed working
    var isTested: Bool {
        switch self {
        case .ollama, .azure, .lmStudio:
            return true
        default:
            return false
        }
    }
}