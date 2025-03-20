//
//  AIServiceFactory.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation

/// 工厂类，用于创建不同类型的AI服务实例
class AIServiceFactory {
    
    /// 创建AI服务实例
    /// - Parameters:
    ///   - provider: API提供商类型
    ///   - settings: 应用设置
    /// - Returns: 符合AIServiceProtocol的服务实例
    static func createService(provider: APIProvider, settings: AppSettings) -> AIServiceProtocol {
        switch provider {
        case .ollama:
            return OllamaAPIService(
                serverAddress: settings.effectiveOllamaServerAddress,
                serverPort: settings.effectiveOllamaServerPort,
                useLocalServer: settings.effectiveUseLocalOllama,
                apiKey: settings.effectiveAPIKey,
                modelName: settings.effectiveAPIModelName
            )
            
        case .azure:
            return AzureAPIService(
                endpoint: settings.effectiveAzureEndpoint,
                deploymentName: settings.effectiveAzureDeploymentName,
                apiVersion: settings.effectiveAzureAPIVersion,
                apiKey: settings.effectiveAPIKey,
                modelName: settings.effectiveAPIModelName
            )
            
        case .lmStudio:
            return LMStudioAPIService(
                serverAddress: settings.effectiveLMStudioServerAddress,
                serverPort: settings.effectiveLMStudioServerPort,
                modelName: settings.effectiveAPIModelName
            )
            
        default:
            // 对于未实现的API提供商，返回一个默认的Ollama服务
            // 在实际使用时会抛出unsupportedProvider错误
            return OllamaAPIService(
                serverAddress: "http://127.0.0.1",
                serverPort: 11434,
                useLocalServer: true,
                apiKey: "",
                modelName: "gemma3:4b"
            )
        }
    }
}