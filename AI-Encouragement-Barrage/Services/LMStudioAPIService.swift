//
//  LMStudioAPIService.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import AppKit
import CoreGraphics

// Service for interacting with LM Studio API
class LMStudioAPIService: AIServiceProtocol {
    private var serverAddress: String
    private var serverPort: Int
    private var modelName: String
    
    init(serverAddress: String, serverPort: Int, modelName: String) {
        self.serverAddress = serverAddress
        self.serverPort = serverPort
        self.modelName = modelName
    }
    
    // MARK: - AIServiceProtocol
    
    var serviceName: String {
        return "LM Studio API"
    }
    
    var currentModelName: String {
        return modelName
    }
    
    var supportsImageAnalysis: Bool {
        return false // LM Studio 目前不支持图像分析
    }
    
    // Fetch available LM Studio models
    func fetchModels() async throws -> [LMStudioModel] {
        // Build API endpoint
        let baseURL = "\(serverAddress):\(serverPort)"
        let endpoint = "\(baseURL)/v1/models"
        
        print("Fetching LM Studio models from: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10 // Set timeout to 10 seconds
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.requestFailed
        }
        
        if httpResponse.statusCode != 200 {
            throw AIServiceError.apiError(message: "HTTP Error \(httpResponse.statusCode)", statusCode: httpResponse.statusCode)
        }
        
        // Parse response
        if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let models = jsonResponse["data"] as? [[String: Any]] {
            
            print("Found \(models.count) LM Studio models")
            
            // Create a temporary array to hold the parsed models
            var parsedModels: [LMStudioModel] = []
            
            // Process each model
            for modelDict in models {
                // Extract required fields with safe type casting
                if let id = modelDict["id"] as? String {
                    // Get optional fields
                    let owned_by = modelDict["owned_by"] as? String ?? "Unknown"
                    
                    // Create date string
                    var createdString = "Unknown"
                    if let created = modelDict["created"] as? Int {
                        let date = Date(timeIntervalSince1970: TimeInterval(created))
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .none
                        createdString = dateFormatter.string(from: date)
                    }
                    
                    // Create and add the model
                    let model = LMStudioModel(
                        id: id,
                        created: createdString,
                        owned_by: owned_by
                    )
                    
                    parsedModels.append(model)
                }
            }
            
            return parsedModels
        } else {
            throw AIServiceError.invalidResponse
        }
    }
    
    // Send request to LM Studio API
    func sendRequest(prompt: String, imageBase64: String?, useStreaming: Bool = false, streamHandler: ((String) -> Void)? = nil) async throws -> String {
        // Build API endpoint
        let baseURL = "\(serverAddress):\(serverPort)"
        let endpoint = "\(baseURL)/v1/chat/completions"
        
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidURL
        }
        
        // Debug log
        print("Sending request to LM Studio API")
        print("Server: \(serverAddress):\(serverPort)")
        print("Model: \(modelName)")
        
        // Build messages array
        var messages: [[String: Any]] = [
            ["role": "system", "content": "你是一个桌面助手。会发弹幕关心和帮助用户。也会作为一个朋友说一些友善的话。"]
        ]
        
        // If image is provided, add it to the user message
        if let _ = imageBase64 {
            // For now, we'll just add a note about the image
            messages.append([
                "role": "user",
                "content": "\(prompt)\n[注意：用户发送了一张图片，但当前模型可能不支持图像分析]"
            ])
        } else {
            messages.append([
                "role": "user",
                "content": prompt
            ])
        }
        
        // Build request body
        let requestBody: [String: Any] = [
            "model": modelName,
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
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.requestFailed
        }
        
        if httpResponse.statusCode != 200 {
            throw AIServiceError.apiError(message: "HTTP Error \(httpResponse.statusCode)", statusCode: httpResponse.statusCode)
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
