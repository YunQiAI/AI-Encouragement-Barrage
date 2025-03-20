import Foundation

class BarrageViewModel: ObservableObject {
    // ...existing code...
    
    @Published var barrageMessages: [String] = []
    private let azureService = AzureOpenAIService(
        endpoint: APIConfig.AzureOpenAI.endpoint,
        apiKey: APIConfig.AzureOpenAI.apiKey,
        deploymentId: APIConfig.AzureOpenAI.deploymentId
    )
    
    func generateEncouragement(for prompt: String) async {
        do {
            let response = try await azureService.generateResponse(prompt: prompt)
            DispatchQueue.main.async {
                self.barrageMessages.append(response)
            }
        } catch {
            print("生成鼓励内容失败: \(error)")
        }
    }
    
    // ...existing code...
}
