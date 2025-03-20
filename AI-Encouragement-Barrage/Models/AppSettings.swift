//
//  AppSettings.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation
import SwiftData

@Model
class AppSettings {
    // Screen capture interval (seconds)
    var captureInterval: Double
    
    // Barrage speed (1.0 is normal speed)
    var barrageSpeed: Double
    
    // Whether to enable speech
    var speechEnabled: Bool
    
    // Voice identifier for Siri TTS
    var voiceIdentifier: String?
    
    // Barrage movement direction - optional to solve migration issues
    var barrageDirection: String?
    
    // Barrage travel range - optional to solve migration issues
    var barrageTravelRange: Double?
    
    // API Provider - optional to solve migration issues
    var apiProvider: String?
    
    // Azure OpenAI API settings - optional to solve migration issues
    var azureEndpoint: String?
    var azureDeploymentName: String?
    var azureAPIVersion: String?
    
    // Ollama API settings - optional to solve migration issues
    var ollamaServerAddress: String?
    var ollamaServerPort: Int?
    var useLocalOllama: Bool?
    var ollamaModelName: String?
    var ollamaAPIKey: String?
    
    // General API settings - optional to solve migration issues
    var apiModelName: String?
    var apiKey: String?
    
    init(
        captureInterval: Double = 20.0,
        barrageSpeed: Double = 1.0,
        speechEnabled: Bool = true,
        voiceIdentifier: String? = "com.apple.voice.siri.female.zh-CN",
        barrageDirection: String? = "rightToLeft",
        barrageTravelRange: Double? = 1.0,
        apiProvider: String? = "Ollama API",
        azureEndpoint: String? = "https://your-resource-name.openai.azure.com",
        azureDeploymentName: String? = "gpt-4o",
        azureAPIVersion: String? = "2023-12-01-preview",
        ollamaServerAddress: String? = "http://127.0.0.1",
        ollamaServerPort: Int? = 11434,
        useLocalOllama: Bool? = true,
        ollamaModelName: String? = "gemma3:4b",
        ollamaAPIKey: String? = "",
        apiModelName: String? = "",
        apiKey: String? = ""
    ) {
        self.captureInterval = captureInterval
        self.barrageSpeed = barrageSpeed
        self.speechEnabled = speechEnabled
        self.voiceIdentifier = voiceIdentifier
        self.barrageDirection = barrageDirection
        self.barrageTravelRange = barrageTravelRange
        self.apiProvider = apiProvider
        self.azureEndpoint = azureEndpoint
        self.azureDeploymentName = azureDeploymentName
        self.azureAPIVersion = azureAPIVersion
        self.ollamaServerAddress = ollamaServerAddress
        self.ollamaServerPort = ollamaServerPort
        self.useLocalOllama = useLocalOllama
        self.ollamaModelName = ollamaModelName
        self.ollamaAPIKey = ollamaAPIKey
        self.apiModelName = apiModelName
        self.apiKey = apiKey
    }
    
    // Get effective voice identifier
    var effectiveVoiceIdentifier: String {
        return voiceIdentifier ?? "com.apple.voice.siri.female.zh-CN"
    }
    
    // Get effective API provider
    var effectiveAPIProvider: APIProvider {
        guard let providerString = apiProvider,
              let provider = APIProvider.allCases.first(where: { $0.rawValue == providerString }) else {
            return .ollama
        }
        return provider
    }
    
    // Get effective API model name
    var effectiveAPIModelName: String {
        if let model = apiModelName, !model.isEmpty {
            return model
        }
        return effectiveAPIProvider.defaultModel
    }
    
    // Get effective API key
    var effectiveAPIKey: String {
        return apiKey ?? ""
    }
    
    // Get effective Azure endpoint
    var effectiveAzureEndpoint: String {
        return azureEndpoint ?? "https://your-resource-name.openai.azure.com"
    }
    
    // Get effective Azure deployment name
    var effectiveAzureDeploymentName: String {
        return azureDeploymentName ?? "gpt-4o"
    }
    
    // Get effective Azure API version
    var effectiveAzureAPIVersion: String {
        return azureAPIVersion ?? "2023-12-01-preview"
    }
    
    // Get effective Ollama server address
    var effectiveOllamaServerAddress: String {
        return ollamaServerAddress ?? "http://127.0.0.1"
    }
    
    // Get effective Ollama server port
    var effectiveOllamaServerPort: Int {
        return ollamaServerPort ?? 11434
    }
    
    // Get effective use local Ollama setting
    var effectiveUseLocalOllama: Bool {
        return useLocalOllama ?? true
    }
    
    // Get effective Ollama model name
    var effectiveOllamaModelName: String {
        return ollamaModelName ?? "gemma3:4b"
    }
    
    // Get effective Ollama API key
    var effectiveOllamaAPIKey: String {
        return ollamaAPIKey ?? ""
    }
}