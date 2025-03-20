//
//  OllamaService.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import AppKit
import CoreGraphics

class OllamaService: ObservableObject {
    private var serverAddress: String
    private var serverPort: Int
    private var modelName: String
    private var useLocalOllama: Bool
    private var apiKey: String
    
    init(settings: AppSettings? = nil) {
        if let settings = settings {
            self.serverAddress = settings.effectiveOllamaServerAddress
            self.serverPort = settings.effectiveOllamaServerPort
            self.modelName = settings.effectiveOllamaModelName
            self.useLocalOllama = settings.effectiveUseLocalOllama
            self.apiKey = settings.effectiveOllamaAPIKey
        } else {
            // 默认值
            self.serverAddress = "http://127.0.0.1"
            self.serverPort = 11434
            self.modelName = "gemma3:4b"
            self.useLocalOllama = true
            self.apiKey = ""
        }
    }
    
    // 更新配置
    func updateConfig(settings: AppSettings) {
        self.serverAddress = settings.effectiveOllamaServerAddress
        self.serverPort = settings.effectiveOllamaServerPort
        self.modelName = settings.effectiveOllamaModelName
        self.useLocalOllama = settings.effectiveUseLocalOllama
        self.apiKey = settings.effectiveOllamaAPIKey
    }
    
    // 分析图像并生成鼓励语
    func analyzeImage(image: CGImage) async throws -> String {
        // 将CGImage转换为Data
        guard let imageData = convertCGImageToData(image) else {
            throw OllamaError.imageConversionFailed
        }
        
        // 将图像数据转换为Base64编码
        let base64Image = imageData.base64EncodedString()
        
        // 构建提示词
        let prompt = """
        你是一个积极鼓励的AI助手。请分析这张截图，了解用户正在做什么，然后生成一条简短、积极、鼓舞人心的鼓励语。
        鼓励语应该与用户当前的活动相关，例如：
        - 如果用户在写代码，可以称赞他们的编程技巧或进度
        - 如果用户在写文档，可以称赞他们的表达能力或思路
        - 如果用户在玩游戏，可以称赞他们的游戏技巧
        
        请确保鼓励语简短（不超过30个字），积极正面，不要提出问题或建议。
        只返回鼓励语本身，不要包含任何其他解释或前缀。
        """
        
        // 发送请求到Ollama API
        return try await sendRequest(prompt: prompt, imageBase64: base64Image)
    }
    
    // 分析文本并生成回复
    func analyzeText(text: String) async throws -> String {
        // 构建提示词
        let prompt = """
        你是一个积极鼓励的AI助手。请回复用户的消息，保持积极、友好和鼓励的态度。
        
        用户消息: \(text)
        
        请提供一个有帮助、积极且鼓舞人心的回复。如果用户询问问题，提供有用的信息；如果用户分享成就，给予赞美；如果用户表达困难，提供鼓励和支持。
        """
        
        // 发送请求到Ollama API（不包含图像）
        return try await sendRequest(prompt: prompt, imageBase64: nil)
    }
    
    // 将CGImage转换为JPEG数据
    private func convertCGImageToData(_ image: CGImage) -> Data? {
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
    }
    
    // 发送请求到Ollama API
    private func sendRequest(prompt: String, imageBase64: String?) async throws -> String {
        // 构建API端点
        let baseURL: String
        if useLocalOllama {
            baseURL = "\(serverAddress):\(serverPort)"
        } else {
            baseURL = "https://api.ollama.com/v1"
        }
        
        let endpoint = "\(baseURL)/api/generate"
        
        guard let url = URL(string: endpoint) else {
            throw OllamaError.invalidURL
        }
        
        // 构建请求体
        var requestBody: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": 0.7,
                "top_p": 0.9
            ]
        ]
        
        // 如果有图像，添加到请求中
        if let imageBase64 = imageBase64 {
            requestBody["images"] = [imageBase64]
        }
        
        // 将请求体转换为JSON数据
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OllamaError.jsonEncodingFailed
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 如果使用远程API，添加API密钥
        if !useLocalOllama && !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 检查响应状态码
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.requestFailed
        }
        
        if httpResponse.statusCode != 200 {
            // 尝试解析错误信息
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw OllamaError.apiError(message: errorMessage, statusCode: httpResponse.statusCode)
            } else {
                throw OllamaError.apiError(message: "未知错误", statusCode: httpResponse.statusCode)
            }
        }
        
        // 解析响应
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = jsonResponse["response"] as? String else {
            throw OllamaError.invalidResponse
        }
        
        return responseText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// 错误类型
enum OllamaError: Error, LocalizedError {
    case imageConversionFailed
    case invalidURL
    case jsonEncodingFailed
    case requestFailed
    case invalidResponse
    case apiError(message: String, statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "图像转换失败"
        case .invalidURL:
            return "无效的URL"
        case .jsonEncodingFailed:
            return "JSON编码失败"
        case .requestFailed:
            return "请求失败"
        case .invalidResponse:
            return "无效的响应"
        case .apiError(let message, let statusCode):
            return "API错误(\(statusCode)): \(message)"
        }
    }
}
