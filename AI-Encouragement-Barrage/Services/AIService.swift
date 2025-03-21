//
//  AIService.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation

/// AI服务 - 负责生成鼓励性文本
class AIService {
    private let settings: AppSettings
    
    init(settings: AppSettings) {
        self.settings = settings
    }
    
    /// 分析文本并生成鼓励性回应
    /// - Parameter text: 用户输入的文本
    /// - Returns: 生成的鼓励性文本
    func analyzeText(text: String) async throws -> String {
        // 使用提示词构建请求
        let prompt = """
        你是一个桌面助手。请根据用户的输入生成100条简短、积极、鼓励的弹幕消息。
        每条消息不超过20个字符，每条消息占一行。
        
        用户输入: \(text)
        
        请用不同的表达方式生成鼓励性的弹幕消息，确保消息多样化且与用户输入相关。
        """
        
        // 获取API设置
        let apiProvider = APIProvider(rawValue: settings.apiProvider) ?? .ollama
        let modelName = settings.effectiveAPIModelName
        let apiKey = settings.effectiveAPIKey
        
        // 如果使用模拟数据，则返回模拟响应
        if apiProvider == .mock {
            let mockResponses = generateMockBarrages(context: text, count: 100)
            try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟网络延迟
            return mockResponses.joined(separator: "\n")
        }
        
        // 构建API请求
        guard let url = URL(string: apiProvider.baseURL) else {
            throw AIServiceError.invalidInput
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加API密钥（如果需要）
        if apiProvider.requiresAPIKey {
            if apiKey.isEmpty {
                throw AIServiceError.requestFailed
            }
            
            switch apiProvider {
            case .openRouter:
                request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            default:
                break
            }
        }
        
        // 构建请求体
        var requestBody: [String: Any] = [:]
        
        switch apiProvider {
        case .ollama:
            requestBody = [
                "model": modelName,
                "messages": [
                    ["role": "system", "content": "你是一个生成简短鼓励消息的助手。"],
                    ["role": "user", "content": prompt]
                ],
                "stream": false
            ]
        case .lmStudio, .openRouter:
            requestBody = [
                "model": modelName,
                "messages": [
                    ["role": "system", "content": "你是一个生成简短鼓励消息的助手。"],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.7,
                "max_tokens": 1000
            ]
        default:
            break
        }
        
        // 序列化请求体
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 检查响应状态
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("服务器错误 (\(httpResponse.statusCode)): \(errorMessage)")
            throw AIServiceError.requestFailed
        }
        
        // 解析响应
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIServiceError.requestFailed
        }
        
        // 提取生成的文本
        var generatedText = ""
        
        switch apiProvider {
        case .ollama:
            if let message = (json["message"] as? [String: Any])?["content"] as? String {
                generatedText = message
            }
        case .lmStudio, .openRouter:
            if let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                generatedText = content
            }
        default:
            break
        }
        
        if generatedText.isEmpty {
            throw AIServiceError.requestFailed
        }
        
        // 处理生成的文本，提取每行作为单独的弹幕
        let lines = generatedText.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // 如果没有有效的行，则使用模拟数据
        if lines.isEmpty {
            let mockResponses = generateMockBarrages(context: text, count: 100)
            return mockResponses.joined(separator: "\n")
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// 测试API连接
    /// - Returns: 测试结果消息
    func testAPIConnection() async -> String {
        let apiProvider = APIProvider(rawValue: settings.apiProvider) ?? .ollama
        let modelName = settings.effectiveAPIModelName
        
        // 如果是模拟数据，直接返回成功
        if apiProvider == .mock {
            return "模拟数据测试成功"
        }
        
        // 构建简单的测试请求
        guard let url = URL(string: apiProvider.baseURL) else {
            return "错误: 无效的API URL"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加API密钥（如果需要）
        if apiProvider.requiresAPIKey {
            if settings.apiKey.isEmpty {
                return "错误: 缺少API密钥"
            }
            
            switch apiProvider {
            case .openRouter:
                request.addValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
            default:
                break
            }
        }
        
        // 构建请求体
        var requestBody: [String: Any] = [:]
        
        switch apiProvider {
        case .ollama:
            requestBody = [
                "model": modelName,
                "messages": [
                    ["role": "user", "content": "你好"]
                ],
                "stream": false
            ]
        case .lmStudio, .openRouter:
            requestBody = [
                "model": modelName,
                "messages": [
                    ["role": "user", "content": "你好"]
                ],
                "temperature": 0.7,
                "max_tokens": 10
            ]
        default:
            break
        }
        
        do {
            // 序列化请求体
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            // 发送请求
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查响应状态
            guard let httpResponse = response as? HTTPURLResponse else {
                return "错误: 无效的响应"
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
                return "错误: 服务器返回 \(httpResponse.statusCode) - \(errorMessage)"
            }
            
            return "连接测试成功！API响应正常。"
        } catch {
            return "错误: \(error.localizedDescription)"
        }
    }
    
    /// 生成模拟弹幕
    /// - Parameters:
    ///   - context: 上下文
    ///   - count: 生成数量
    /// - Returns: 弹幕数组
    private func generateMockBarrages(context: String, count: Int) -> [String] {
        // 通用响应
        let commonResponses = [
            "继续加油！",
            "你很棒！",
            "坚持下去！",
            "不要放弃！",
            "相信自己！",
            "你能行！",
            "做得好！",
            "真不错！",
            "太厉害了！",
            "了不起！",
            "真棒！",
            "加油！",
            "很有进步！",
            "真优秀！",
            "好样的！",
            "很出色！",
            "真不错！",
            "很专业！",
            "很用心！",
            "很细心！"
        ]
        
        var results: [String] = []
        
        // 生成指定数量的弹幕
        for _ in 0..<count {
            if let base = commonResponses.randomElement() {
                results.append(base)
            }
        }
        
        return results
    }
}
