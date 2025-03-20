//
//  AzureAPIService.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import AppKit
import CoreGraphics

// Service for interacting with Azure OpenAI API
class AzureAPIService: AIServiceProtocol {
    private var endpoint: String
    private var deploymentName: String
    private var apiVersion: String
    private var apiKey: String
    private var modelName: String
    
    init(endpoint: String, deploymentName: String, apiVersion: String, apiKey: String, modelName: String) {
        self.endpoint = endpoint
        self.deploymentName = deploymentName
        self.apiVersion = apiVersion
        self.apiKey = apiKey
        self.modelName = modelName
    }
    
    // MARK: - AIServiceProtocol
    
    var serviceName: String {
        return "Azure OpenAI API"
    }
    
    var currentModelName: String {
        return modelName
    }
    
    var supportsStreaming: Bool {
        return false // Azure API 当前实现不支持流式响应
    }
    
    // Send request to Azure OpenAI API
    func sendRequest(prompt: String, imageBase64: String?, useStreaming: Bool = false, streamHandler: ((String) -> Void)? = nil) async throws -> String {
        // Debug log
        print("Sending request to Azure OpenAI API")
        print("Endpoint: \(endpoint)")
        print("Deployment: \(deploymentName)")
        print("API Version: \(apiVersion)")
        print("Model: \(modelName)")
        
        // Build API endpoint
        // For Azure OpenAI API, the endpoint format is:
        // {endpoint}/openai/deployments/{deployment-id}/chat/completions?api-version={api-version}
        let apiEndpoint = "\(endpoint)/openai/deployments/\(deploymentName)/chat/completions?api-version=\(apiVersion)"
        
        guard let url = URL(string: apiEndpoint) else {
            throw AIServiceError.invalidURL
        }
        
        // Build messages array
        var messages: [[String: Any]] = [
            ["role": "system", "content": "你是一个桌面助手。会发弹幕关心和帮助用户。也会作为一个朋友说一些友善的话。"]
        ]
        
        // If image is provided, add it to the user message
        if let imageBase64 = imageBase64 {
            messages.append([
                "role": "user",
                "content": [
                    ["type": "text", "text": prompt],
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(imageBase64)"]]
                ]
            ])
        } else {
            messages.append([
                "role": "user",
                "content": prompt
            ])
        }
        
        // Build request body
        let requestBody: [String: Any] = [
            "messages": messages,
            "max_tokens": 150,
            "temperature": 0.7,
            "top_p": 0.9
        ]
        
        // Convert request body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw AIServiceError.jsonEncodingFailed
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "api-key") // Azure uses api-key header, not Bearer token
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.requestFailed
        }
        
        // Debug log
        print("Azure API response status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Azure API response: \(responseString)")
        }
        
        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let errorMessage = error["message"] as? String {
                throw AIServiceError.apiError(message: errorMessage, statusCode: httpResponse.statusCode)
            } else if let errorString = String(data: data, encoding: .utf8) {
                throw AIServiceError.apiError(message: errorString, statusCode: httpResponse.statusCode)
            } else {
                throw AIServiceError.apiError(message: "HTTP Error \(httpResponse.statusCode)", statusCode: httpResponse.statusCode)
            }
        }
        
        // Parse response
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = jsonResponse["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}