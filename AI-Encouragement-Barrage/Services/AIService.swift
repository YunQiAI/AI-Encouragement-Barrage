//
//  AIService.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import AppKit
import CoreGraphics

class AIService: ObservableObject {
    // API configuration
    private var apiProvider: APIProvider
    private var apiModelName: String
    private var apiKey: String
    
    // Ollama specific settings
    private var ollamaServerAddress: String
    private var ollamaServerPort: Int
    private var useLocalOllama: Bool
    
    // Azure specific settings
    private var azureEndpoint: String
    private var azureDeploymentName: String
    private var azureAPIVersion: String
    
    // Published properties for UI updates
    @Published var availableOllamaModels: [OllamaModel] = []
    @Published var isLoadingModels: Bool = false
    @Published var modelLoadError: String? = nil
    
    init(settings: AppSettings? = nil) {
        if let settings = settings {
            self.apiProvider = settings.effectiveAPIProvider
            self.apiModelName = settings.effectiveAPIModelName
            self.apiKey = settings.effectiveAPIKey
            
            // Ollama specific settings
            self.ollamaServerAddress = settings.effectiveOllamaServerAddress
            self.ollamaServerPort = settings.effectiveOllamaServerPort
            self.useLocalOllama = settings.effectiveUseLocalOllama
            
            // Azure specific settings
            self.azureEndpoint = settings.effectiveAzureEndpoint
            self.azureDeploymentName = settings.effectiveAzureDeploymentName
            self.azureAPIVersion = settings.effectiveAzureAPIVersion
        } else {
            // Default values
            self.apiProvider = .ollama
            self.apiModelName = "gemma3:4b"
            self.apiKey = ""
            
            // Ollama specific settings
            self.ollamaServerAddress = "http://127.0.0.1"
            self.ollamaServerPort = 11434
            self.useLocalOllama = true
            
            // Azure specific settings
            self.azureEndpoint = "https://your-resource-name.openai.azure.com"
            self.azureDeploymentName = "gpt-4o"
            self.azureAPIVersion = "2023-12-01-preview" // Updated to latest version that supports gpt-4o
        }
        
        // Load available Ollama models
        if self.apiProvider == .ollama && self.useLocalOllama {
            Task {
                await self.fetchOllamaModels()
            }
        }
    }
    
    // Update configuration
    func updateConfig(settings: AppSettings) {
        let oldProvider = self.apiProvider
        let oldUseLocalOllama = self.useLocalOllama
        let oldServerAddress = self.ollamaServerAddress
        let oldServerPort = self.ollamaServerPort
        
        self.apiProvider = settings.effectiveAPIProvider
        self.apiModelName = settings.effectiveAPIModelName
        self.apiKey = settings.effectiveAPIKey
        
        // Ollama specific settings
        self.ollamaServerAddress = settings.effectiveOllamaServerAddress
        self.ollamaServerPort = settings.effectiveOllamaServerPort
        self.useLocalOllama = settings.effectiveUseLocalOllama
        
        // Azure specific settings
        self.azureEndpoint = settings.effectiveAzureEndpoint
        self.azureDeploymentName = settings.effectiveAzureDeploymentName
        self.azureAPIVersion = settings.effectiveAzureAPIVersion
        
        // If Ollama settings changed, refresh model list
        if self.apiProvider == .ollama && self.useLocalOllama && 
           (oldProvider != .ollama || !oldUseLocalOllama || 
            oldServerAddress != self.ollamaServerAddress || 
            oldServerPort != self.ollamaServerPort) {
            Task {
                await self.fetchOllamaModels()
            }
        }
    }
    
    // Test text chat functionality
    func testTextChat(apiProvider: APIProvider, modelName: String, apiKey: String) async -> String {
        // Create temporary settings for the test
        let tempSettings = AppSettings()
        tempSettings.apiProvider = apiProvider.rawValue
        tempSettings.apiModelName = modelName
        tempSettings.apiKey = apiKey
        
        // If testing Ollama, set Ollama-specific settings
        if apiProvider == .ollama {
            tempSettings.ollamaServerAddress = self.ollamaServerAddress
            tempSettings.ollamaServerPort = self.ollamaServerPort
            tempSettings.useLocalOllama = self.useLocalOllama
            tempSettings.ollamaModelName = modelName
        }
        
        // If testing Azure, set Azure-specific settings
        if apiProvider == .azure {
            tempSettings.azureEndpoint = self.azureEndpoint
            tempSettings.azureDeploymentName = self.azureDeploymentName
            tempSettings.azureAPIVersion = self.azureAPIVersion
        }
        
        // Create a temporary AIService with the test settings
        let testService = AIService(settings: tempSettings)
        
        do {
            // Send a simple test message
            let response = try await testService.analyzeText(text: "你好，这是一个测试消息。")
            return "测试成功: \(response)"
        } catch {
            if let aiError = error as? AIServiceError {
                return "测试失败: \(aiError.errorDescription ?? "未知错误")"
            } else {
                return "测试失败: \(error.localizedDescription)"
            }
        }
    }
    
    // Test image chat functionality
    func testImageChat(apiProvider: APIProvider, modelName: String, apiKey: String) async -> String {
        // Create temporary settings for the test
        let tempSettings = AppSettings()
        tempSettings.apiProvider = apiProvider.rawValue
        tempSettings.apiModelName = modelName
        tempSettings.apiKey = apiKey
        
        // If testing Ollama, set Ollama-specific settings
        if apiProvider == .ollama {
            tempSettings.ollamaServerAddress = self.ollamaServerAddress
            tempSettings.ollamaServerPort = self.ollamaServerPort
            tempSettings.useLocalOllama = self.useLocalOllama
            tempSettings.ollamaModelName = modelName
        }
        
        // If testing Azure, set Azure-specific settings
        if apiProvider == .azure {
            tempSettings.azureEndpoint = self.azureEndpoint
            tempSettings.azureDeploymentName = self.azureDeploymentName
            tempSettings.azureAPIVersion = self.azureAPIVersion
        }
        
        // Create a temporary AIService with the test settings
        let testService = AIService(settings: tempSettings)
        
        // Try to load a test image
        guard let testImage = loadTestImage() else {
            return "测试失败: 无法加载测试图片"
        }
        
        do {
            // Send the test image for analysis
            let response = try await testService.analyzeImage(image: testImage)
            return "测试成功: \(response)"
        } catch {
            if let aiError = error as? AIServiceError {
                return "测试失败: \(aiError.errorDescription ?? "未知错误")"
            } else {
                return "测试失败: \(error.localizedDescription)"
            }
        }
    }
    
    // Load test image from bundle
    private func loadTestImage() -> CGImage? {
        if let image = NSImage(named: "test_image") {
            return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
        
        // Try to load from assets
        if let image = NSImage(named: NSImage.Name("test_image")) {
            return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
        
        return nil
    }
    
    // Fetch available Ollama models
    @MainActor
    func fetchOllamaModels() async {
        guard apiProvider == .ollama && useLocalOllama else {
            availableOllamaModels = []
            return
        }
        
        isLoadingModels = true
        modelLoadError = nil
        
        // Build API endpoint
        let baseURL = "\(ollamaServerAddress):\(ollamaServerPort)"
        let endpoint = "\(baseURL)/api/tags"
        
        print("Fetching Ollama models from: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            modelLoadError = "Invalid URL"
            isLoadingModels = false
            return
        }
        
        do {
            // Create request
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 10 // Set timeout to 10 seconds
            
            // Send request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status code
            guard let httpResponse = response as? HTTPURLResponse else {
                modelLoadError = "Request failed"
                isLoadingModels = false
                return
            }
            
            if httpResponse.statusCode != 200 {
                modelLoadError = "API error: \(httpResponse.statusCode)"
                isLoadingModels = false
                return
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw response: \(responseString)")
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
                        print("Successfully parsed model: \(name)")
                    } else {
                        print("Failed to parse model: \(modelDict)")
                    }
                }
                
                // Update the published property with the parsed models
                self.availableOllamaModels = parsedModels
                
                // Debug log
                print("Fetched \(self.availableOllamaModels.count) models: \(self.availableOllamaModels.map { $0.name }.joined(separator: ", "))")
            } else {
                modelLoadError = "Invalid response format"
                print("Failed to parse response as JSON")
            }
        } catch {
            modelLoadError = "Error: \(error.localizedDescription)"
            print("Error fetching models: \(error.localizedDescription)")
        }
        
        isLoadingModels = false
    }
    
    // Format file size to human-readable string
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // Analyze image and generate encouragement
    func analyzeImage(image: CGImage) async throws -> String {
        // Convert CGImage to Data
        guard let imageData = convertCGImageToData(image) else {
            throw AIServiceError.imageConversionFailed
        }
        
        // Convert image data to Base64 encoding
        let base64Image = imageData.base64EncodedString()
        
        // Build prompt
        let prompt = """
        You are an encouraging AI assistant. Please analyze this screenshot, understand what the user is doing, and generate a short, positive, uplifting encouragement.
        The encouragement should be related to the user's current activity, for example:
        - If the user is coding, praise their programming skills or progress
        - If the user is writing a document, praise their expression or ideas
        - If the user is playing a game, praise their gaming skills
        
        Please ensure the encouragement is brief (no more than 30 characters), positive, and doesn't ask questions or make suggestions.
        Return only the encouragement itself, without any other explanation or prefix.
        """
        
        // Send request to appropriate API
        return try await sendRequest(prompt: prompt, imageBase64: base64Image)
    }
    
    // Analyze text and generate reply
    func analyzeText(text: String) async throws -> String {
        // Build prompt
        let prompt = """
        You are an encouraging AI assistant. Please reply to the user's message with a positive, friendly, and encouraging attitude.
        
        User message: \(text)
        
        Please provide a helpful, positive, and uplifting response. If the user asks a question, provide useful information; if the user shares an achievement, offer praise; if the user expresses difficulty, provide encouragement and support.
        """
        
        // Send request to appropriate API (without image)
        return try await sendRequest(prompt: prompt, imageBase64: nil)
    }
    
    // Convert CGImage to JPEG data
    private func convertCGImageToData(_ image: CGImage) -> Data? {
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
    }
    
    // Send request to appropriate API
    private func sendRequest(prompt: String, imageBase64: String?) async throws -> String {
        switch apiProvider {
        case .ollama:
            return try await sendOllamaRequest(prompt: prompt, imageBase64: imageBase64)
        case .azure:
            return try await sendAzureRequest(prompt: prompt, imageBase64: imageBase64)
        default:
            throw AIServiceError.unsupportedProvider(provider: apiProvider.rawValue)
        }
    }
    
    // Send request to Ollama API
    private func sendOllamaRequest(prompt: String, imageBase64: String?) async throws -> String {
        // Build API endpoint
        let baseURL: String
        if useLocalOllama {
            baseURL = "\(ollamaServerAddress):\(ollamaServerPort)"
        } else {
            baseURL = "https://api.ollama.com/v1"
        }
        
        let endpoint = "\(baseURL)/api/generate"
        
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidURL
        }
        
        // Debug log
        print("Sending request to Ollama API with model: \(apiModelName)")
        
        // Build request body
        var requestBody: [String: Any] = [
            "model": apiModelName,
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
        if !useLocalOllama && !apiKey.isEmpty {
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
                throw AIServiceError.apiError(message: "Unknown error", statusCode: httpResponse.statusCode)
            }
        }
        
        // Parse response
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responseText = jsonResponse["response"] as? String else {
            throw AIServiceError.invalidResponse
        }
        
        return responseText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Send request to Azure OpenAI API
    private func sendAzureRequest(prompt: String, imageBase64: String?) async throws -> String {
        // Debug log
        print("Sending request to Azure OpenAI API")
        print("Endpoint: \(azureEndpoint)")
        print("Deployment: \(azureDeploymentName)")
        print("API Version: \(azureAPIVersion)")
        print("Model: \(apiModelName)")
        
        // Build API endpoint
        // For Azure OpenAI API, the endpoint format is:
        // {endpoint}/openai/deployments/{deployment-id}/chat/completions?api-version={api-version}
        let endpoint = "\(azureEndpoint)/openai/deployments/\(azureDeploymentName)/chat/completions?api-version=\(azureAPIVersion)"
        
        guard let url = URL(string: endpoint) else {
            throw AIServiceError.invalidURL
        }
        
        // Build messages array
        var messages: [[String: Any]] = [
            ["role": "system", "content": "You are an encouraging AI assistant that provides positive, uplifting responses."]
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
                throw AIServiceError.apiError(message: "Unknown error", statusCode: httpResponse.statusCode)
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

// Ollama model structure
struct OllamaModel: Identifiable, Hashable {
    let name: String
    let id: String
    let size: String
    let modified: String
    
    var displayName: String {
        return "\(name) (\(size))"
    }
}

// Error types
enum AIServiceError: Error, LocalizedError {
    case imageConversionFailed
    case invalidURL
    case jsonEncodingFailed
    case requestFailed
    case invalidResponse
    case apiError(message: String, statusCode: Int)
    case unsupportedProvider(provider: String)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Image conversion failed"
        case .invalidURL:
            return "Invalid URL"
        case .jsonEncodingFailed:
            return "JSON encoding failed"
        case .requestFailed:
            return "Request failed"
        case .invalidResponse:
            return "Invalid response"
        case .apiError(let message, let statusCode):
            return "API error (\(statusCode)): \(message)"
        case .unsupportedProvider(let provider):
            return "Unsupported API provider: \(provider)"
        }
    }
}
