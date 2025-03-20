import Foundation

struct APIConfig {
    // Ollama配置
    struct Ollama {
        // 默认本地配置
        static let defaultServerAddress = "http://127.0.0.1"
        static let defaultServerPort = 11434
        static let defaultModelName = "gemma3:4b"
        
        // 远程API配置
        static let remoteAPIEndpoint = "https://api.ollama.com/v1"
    }
    
    // Azure OpenAI配置
    struct AzureOpenAI {
        static let endpoint = "https://your-resource-name.openai.azure.com" // 替换为您的Azure端点
        static let apiKey = "your-api-key" // 替换为您的API密钥
        static let deploymentId = "gpt-4o" // 或您在Azure上部署的模型名称
    }
}
