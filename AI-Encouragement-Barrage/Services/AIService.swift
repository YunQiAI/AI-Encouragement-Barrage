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
    
    // LM Studio specific settings
    private var lmStudioServerAddress: String
    private var lmStudioServerPort: Int
    
    // API service instances
    private var ollamaService: OllamaAPIService?
    private var azureService: AzureAPIService?
    private var lmStudioService: LMStudioAPIService?
    
    // Published properties for UI updates
    @Published var availableOllamaModels: [OllamaModel] = []
    @Published var availableLMStudioModels: [LMStudioModel] = []
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
            
            // LM Studio specific settings
            self.lmStudioServerAddress = settings.effectiveLMStudioServerAddress
            self.lmStudioServerPort = settings.effectiveLMStudioServerPort
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
            self.azureAPIVersion = "2023-12-01-preview"
            
            // LM Studio specific settings
            self.lmStudioServerAddress = "http://127.0.0.1"
            self.lmStudioServerPort = 1234
        }
        
        // Initialize API services
        initializeAPIServices()
        
        // Load available models based on provider
        if self.apiProvider == .ollama && self.useLocalOllama {
            Task {
                await self.fetchOllamaModels()
            }
        } else if self.apiProvider == .lmStudio {
            Task {
                await self.fetchLMStudioModels()
            }
        }
    }
    
    // Initialize API services
    private func initializeAPIServices() {
        // Initialize Ollama service
        ollamaService = OllamaAPIService(
            serverAddress: ollamaServerAddress,
            serverPort: ollamaServerPort,
            useLocalServer: useLocalOllama,
            apiKey: apiKey,
            modelName: apiModelName
        )
        
        // Initialize Azure service
        azureService = AzureAPIService(
            endpoint: azureEndpoint,
            deploymentName: azureDeploymentName,
            apiVersion: azureAPIVersion,
            apiKey: apiKey,
            modelName: apiModelName
        )
        
        // Initialize LM Studio service
        lmStudioService = LMStudioAPIService(
            serverAddress: lmStudioServerAddress,
            serverPort: lmStudioServerPort,
            modelName: apiModelName
        )
    }
    
    // Update configuration
    func updateConfig(settings: AppSettings) {
        let oldProvider = self.apiProvider
        let oldUseLocalOllama = self.useLocalOllama
        let oldServerAddress = self.ollamaServerAddress
        let oldServerPort = self.ollamaServerPort
        let oldLMStudioAddress = self.lmStudioServerAddress
        let oldLMStudioPort = self.lmStudioServerPort
        
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
        
        // LM Studio specific settings
        self.lmStudioServerAddress = settings.effectiveLMStudioServerAddress
        self.lmStudioServerPort = settings.effectiveLMStudioServerPort
        
        // Re-initialize API services with new settings
        initializeAPIServices()
        
        // If Ollama settings changed, refresh model list
        if self.apiProvider == .ollama && self.useLocalOllama && 
           (oldProvider != .ollama || !oldUseLocalOllama || 
            oldServerAddress != self.ollamaServerAddress || 
            oldServerPort != self.ollamaServerPort) {
            Task {
                await self.fetchOllamaModels()
            }
        }
        
        // If LM Studio settings changed, refresh model list
        if self.apiProvider == .lmStudio && 
           (oldProvider != .lmStudio || 
            oldLMStudioAddress != self.lmStudioServerAddress || 
            oldLMStudioPort != self.lmStudioServerPort) {
            Task {
                await self.fetchLMStudioModels()
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
        
        // If testing LM Studio, set LM Studio-specific settings
        if apiProvider == .lmStudio {
            tempSettings.lmStudioServerAddress = self.lmStudioServerAddress
            tempSettings.lmStudioServerPort = self.lmStudioServerPort
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
        
        // If testing LM Studio, set LM Studio-specific settings
        if apiProvider == .lmStudio {
            tempSettings.lmStudioServerAddress = self.lmStudioServerAddress
            tempSettings.lmStudioServerPort = self.lmStudioServerPort
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
        
        do {
            if let ollamaService = ollamaService {
                let models = try await ollamaService.fetchModels()
                self.availableOllamaModels = models
            }
        } catch {
            modelLoadError = error.localizedDescription
            print("Error fetching Ollama models: \(error.localizedDescription)")
        }
        
        isLoadingModels = false
    }
    
    // Fetch available LM Studio models
    @MainActor
    func fetchLMStudioModels() async {
        guard apiProvider == .lmStudio else {
            availableLMStudioModels = []
            return
        }
        
        isLoadingModels = true
        modelLoadError = nil
        
        do {
            if let lmStudioService = lmStudioService {
                let models = try await lmStudioService.fetchModels()
                self.availableLMStudioModels = models
            }
        } catch {
            modelLoadError = error.localizedDescription
            print("Error fetching LM Studio models: \(error.localizedDescription)")
        }
        
        isLoadingModels = false
    }
    
    // Analyze image and generate encouragement
    func analyzeImage(image: CGImage) async throws -> String {
        // Convert CGImage to Data
        guard let imageData = convertCGImageToData(image) else {
            throw AIServiceError.imageConversionFailed
        }
        
        // Convert image data to Base64 encoding
        let base64Image = imageData.base64EncodedString()
        
        // 使用中文提示词
        let prompt = """
        你是一个桌面助手。会发弹幕关心和帮助用户。也会作为一个朋友说一些友善的话。
        
        请分析这个截图，了解用户正在做什么，作出积极、友好、鼓励的回应。
        """
        
        // Send request to appropriate API
        return try await sendRequest(prompt: prompt, imageBase64: base64Image)
    }
    
    // Analyze text and generate reply
    func analyzeText(text: String) async throws -> String {
        // 使用中文提示词
        let prompt = """
        你是一个桌面助手。会发弹幕关心和帮助用户。也会作为一个朋友说一些友善的话。
        
        用户消息: \(text)
        
        请提供一个积极、友好、鼓励的回应。
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
            guard let ollamaService = ollamaService else {
                throw AIServiceError.requestFailed
            }
            return try await ollamaService.sendRequest(prompt: prompt, imageBase64: imageBase64)
            
        case .azure:
            guard let azureService = azureService else {
                throw AIServiceError.requestFailed
            }
            return try await azureService.sendRequest(prompt: prompt, imageBase64: imageBase64)
            
        case .lmStudio:
            guard let lmStudioService = lmStudioService else {
                throw AIServiceError.requestFailed
            }
            return try await lmStudioService.sendRequest(prompt: prompt, imageBase64: imageBase64)
            
        default:
            throw AIServiceError.unsupportedProvider(provider: apiProvider.rawValue)
        }
    }
}
