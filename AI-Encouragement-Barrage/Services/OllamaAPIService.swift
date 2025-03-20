//
//  OllamaAPIService.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import AppKit
import CoreGraphics

// Service for interacting with Ollama API
class OllamaAPIService {
    private var serverAddress: String
    private var serverPort: Int
    private var useLocalServer: Bool
    private var apiKey: String
    private var modelName: String
    
    init(serverAddress: String, serverPort: Int, useLocalServer: Bool, apiKey: String, modelName: String) {
        self.serverAddress = serverAddress
        self.serverPort = serverPort
        self.useLocalServer = useLocalServer
        self.apiKey = apiKey
        self.modelName = modelName
    }
    
    // Fetch available Ollama models
    func fetchModels() async throws -> [OllamaModel] {
        // Build API endpoint
        let baseURL = "\(serverAddress):\(serverPort)"
        let endpoint = "\(baseURL)/api/tags"
        
        print("Fetching Ollama models from: \(endpoint)")
        
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
           let models = jsonResponse["models"] as? [[String: Any]] {
            
            print("Found \(models.count) models")
            
            // Create a temporary array to hold the parsed models
            var parsedModels: [OllamaModel] = []
            
            // Process each model
            for modelDict in models {
                // Extract required fields with safe type casting
                if let name = modelDict["name"] as? String,
                   let modelID = modelDict["model"] as? String {
                    
                    // Handle size - could be Int or String
                    var sizeString = "Unknown size"
                    if let size = modelDict["size"] as? Int {
                        sizeString = formatFileSize(size)
                    } else if let size = modelDict["size"] as? String,
                              let sizeInt = Int(size) {
                        sizeString = formatFileSize(sizeInt)
                    }
                    
                    // Handle modified_at - could be Int timestamp or ISO8601 string
                    var modifiedString = "Unknown date"
                    if let modified = modelDict["modified_at"] as? Int {
                        let date = Date(timeIntervalSince1970: TimeInterval(modified))
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .none
                        modifiedString = dateFormatter.string(from: date)
                    } else if let modifiedAtString = modelDict["modified_at"] as? String {
                        // Try ISO8601 format
                        let dateFormatter = ISO8601DateFormatter()
                        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        
                        if let date = dateFormatter.date(from: modifiedAtString) {
                            let displayFormatter = DateFormatter()
                            displayFormatter.dateStyle = .medium
                            displayFormatter.timeStyle = .none
                            modifiedString = displayFormatter.string(from: date)
                        }
                    }
                    
                    // Create and add the model
                    let model = OllamaModel(
                        name: name,
                        id: modelID,
                        size: sizeString,
                        modified: modifiedString
                    )
                    
                    parsedModels.append(model)
                }
            }
            
            return parsedModels
        } else {
            throw AIServiceError.invalidResponse
        }
    }
    
    // Send request to Ollama API
    func sendRequest(prompt: String, imageBase64: String?) async throws -> String {
        // Build API endpoint
        let baseURL: String
        if useLocalServer {
            baseURL = "\(serverAddress):\(serverPort)"
        } else {
            baseURL = "https://api.ollama.com/v1"
        }
        
        let endpoint = "\(baseURL)/api/generate"
        
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidURL
        }
        
        // Debug log
        print("Sending request to Ollama API with model: \(modelName)")
        
        // Build request body
        var requestBody: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "stream": false,
            "options": [
                "temperature": 0.7,
                "top_p": 0.9
            ]
        ]
        
        // If image is provided, add to request
        if let imageBase64 = imageBase64 {
            requestBody["images"] = [imageBase64]
        }
        
        // Convert request body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw AIServiceError.jsonEncodingFailed
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // If using remote API, add API key
        if !useLocalServer && !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.requestFailed
        }
        
        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw AIServiceError.apiError(message: errorMessage, statusCode: httpResponse.statusCode)
            } else {
                throw AIServiceError.apiError(message: "HTTP Error \(httpResponse.statusCode)", statusCode: httpResponse.statusCode)
            }
        }
        
        // Parse response
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = jsonResponse["response"] as? String else {
            throw AIServiceError.invalidResponse
        }
        
        return responseText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Format file size to human-readable string
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}