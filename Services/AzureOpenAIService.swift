import Foundation

struct AzureOpenAIService {
    private let endpoint: String
    private let apiKey: String
    private let deploymentId: String
    
    init(endpoint: String, apiKey: String, deploymentId: String) {
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.deploymentId = deploymentId
    }
    
    func generateResponse(prompt: String) async throws -> String {
        let url = URL(string: "\(endpoint)/openai/deployments/\(deploymentId)/chat/completions?api-version=2023-12-01-preview")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "messages": [
                ["role": "system", "content": "你是一个提供鼓励的AI助手。"],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 1000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let response = try JSONDecoder().decode(AzureOpenAIResponse.self, from: data)
        return response.choices.first?.message.content ?? "无响应"
    }
}

// 响应模型
struct AzureOpenAIResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
        
        struct Message: Decodable {
            let content: String
        }
    }
}
