//
//  APISettingsView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import SwiftUI
import Combine

struct APISettingsView: View {
    @Binding var settings: AppSettings
    
    // API settings
    @State private var selectedAPIProvider: APIProvider = .ollama
    @State private var apiModelName: String = ""
    @State private var apiKey: String = ""
    
    // Ollama API settings
    @State private var ollamaServerAddress: String = "http://127.0.0.1"
    @State private var ollamaServerPort: Int = 11434
    @State private var useLocalOllama: Bool = true
    @State private var ollamaModelName: String = ""
    @State private var ollamaAPIKey: String = ""
    
    // Azure API settings
    @State private var azureEndpoint: String = ""
    @State private var azureDeploymentName: String = ""
    @State private var azureAPIVersion: String = ""
    
    // AI service for model fetching and testing
    @StateObject private var aiService = AIService()
    @State private var testResult: String = ""
    @State private var isTestingAPI: Bool = false
    @State private var isRefreshingModels: Bool = false
    
    var body: some View {
        GroupBox(label: Text("AI Service Configuration").font(.headline)) {
            VStack(alignment: .leading, spacing: 10) {
                // API Provider dropdown
                Text("API Provider:")
                Menu {
                    ForEach(APIProvider.allCases) { provider in
                        Button(action: {
                            selectedAPIProvider = provider
                            // Set default model for the selected provider
                            apiModelName = provider.defaultModel
                            apiKey = "" // Reset API key when switching provider
                            updateSettings()
                        }) {
                            HStack {
                                Text(provider.rawValue)
                                if selectedAPIProvider == provider {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedAPIProvider.rawValue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color(.textBackgroundColor).opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Divider().padding(.vertical, 5)
                
                // Provider-specific settings
                switch selectedAPIProvider {
                case .ollama:
                    ollamaSettingsView
                case .azure:
                    azureSettingsView
                default:
                    generalAPISettingsView
                }
                
                Divider().padding(.vertical, 5)
                
                // Test buttons
                VStack(alignment: .leading, spacing: 10) {
                    Text("测试功能:")
                        .font(.subheadline)
                    
                    HStack {
                        Button(action: {
                            Task {
                                isTestingAPI = true
                                testResult = "Testing..."
                                
                                // Get the correct model name based on the selected provider
                                let modelName = getEffectiveModelName()
                                let key = getEffectiveAPIKey()
                                
                                if modelName.isEmpty {
                                    testResult = "Error: Please fill in model name."
                                } else {
                                    print("Testing text chat with provider: \(selectedAPIProvider.rawValue), model: \(modelName)")
                                    testResult = await aiService.testTextChat(apiProvider: selectedAPIProvider, modelName: modelName, apiKey: key)
                                }
                                
                                isTestingAPI = false
                            }
                        }) {
                            Text("测试文字聊天")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(isTestingAPI)
                        
                        Button(action: {
                            Task {
                                isTestingAPI = true
                                testResult = "Testing..."
                                
                                // Get the correct model name based on the selected provider
                                let modelName = getEffectiveModelName()
                                let key = getEffectiveAPIKey()
                                
                                if modelName.isEmpty {
                                    testResult = "Error: Please fill in model name."
                                } else {
                                    print("Testing image chat with provider: \(selectedAPIProvider.rawValue), model: \(modelName)")
                                    testResult = await aiService.testImageChat(apiProvider: selectedAPIProvider, modelName: modelName, apiKey: key)
                                }
                                
                                isTestingAPI = false
                            }
                        }) {
                            Text("测试图片聊天")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(isTestingAPI)
                    }
                    
                    if !testResult.isEmpty {
                        Text("测试结果: \(testResult)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    }
                }
            }
            .padding(.vertical, 10)
            .onAppear {
                // Initialize values from settings
                initializeFromSettings()
            }
        }
    }
    
    // Get the effective model name based on the selected provider
    private func getEffectiveModelName() -> String {
        switch selectedAPIProvider {
        case .ollama:
            return ollamaModelName
        default:
            return apiModelName
        }
    }
    
    // Get the effective API key based on the selected provider
    private func getEffectiveAPIKey() -> String {
        switch selectedAPIProvider {
        case .ollama:
            return useLocalOllama ? "" : ollamaAPIKey
        default:
            return apiKey
        }
    }
    
    // Ollama API settings view
    private var ollamaSettingsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Ollama settings
            Toggle("Use Local Ollama", isOn: $useLocalOllama)
                .padding(.vertical, 5)
                .onChange(of: useLocalOllama) { _, newValue in
                    if newValue {
                        // Refresh model list when switching to local Ollama
                        refreshOllamaModels()
                    }
                    updateSettings()
                }
            
            if useLocalOllama {
                Text("Local Server Address:")
                TextField("Server Address", text: $ollamaServerAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: ollamaServerAddress) { _, _ in
                        // Update aiService with new address
                        let tempSettings = AppSettings(
                            ollamaServerAddress: ollamaServerAddress,
                            ollamaServerPort: ollamaServerPort,
                            useLocalOllama: useLocalOllama
                        )
                        aiService.updateConfig(settings: tempSettings)
                        updateSettings()
                    }
                
                HStack {
                    Text("Port:")
                    TextField("Port", value: $ollamaServerPort, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .onChange(of: ollamaServerPort) { _, _ in
                            // Update aiService with new port
                            let tempSettings = AppSettings(
                                ollamaServerAddress: ollamaServerAddress,
                                ollamaServerPort: ollamaServerPort,
                                useLocalOllama: useLocalOllama
                            )
                            aiService.updateConfig(settings: tempSettings)
                            updateSettings()
                        }
                }
            } else {
                Text("API Key:")
                SecureField("API Key", text: $ollamaAPIKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: ollamaAPIKey) { _, _ in
                        updateSettings()
                    }
                
                Text("Remote API will use https://api.ollama.com/v1")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider().padding(.vertical, 5)
            
            Text("Model Name:")
            
            // Model selection with dynamic list from Ollama API
            if useLocalOllama {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        TextField("Model Name", text: $ollamaModelName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: ollamaModelName) { _, _ in
                                updateSettings()
                            }
                        
                        // Refresh button
                        Button(action: {
                            refreshOllamaModels()
                        }) {
                            if isRefreshingModels {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 30, height: 30)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .frame(width: 30, height: 30)
                            }
                        }
                        .background(Color(.textBackgroundColor).opacity(0.1))
                        .cornerRadius(8)
                        .buttonStyle(.plain)
                        .disabled(isRefreshingModels)
                    }
                    
                    // Show loading indicator or model list
                    if aiService.isLoadingModels {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Loading models...")
                                .font(.caption)
                        }
                        .padding(.vertical, 5)
                    } else if let error = aiService.modelLoadError {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if aiService.availableOllamaModels.isEmpty {
                        Text("No models found. Click refresh to load models.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        // Model dropdown menu
                        Menu {
                            ForEach(aiService.availableOllamaModels) { model in
                                Button(action: {
                                    ollamaModelName = model.name
                                    updateSettings()
                                    print("Selected model from dropdown: \(model.name)")
                                }) {
                                    HStack {
                                        Text("\(model.name) (\(model.size))")
                                        if ollamaModelName == model.name {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("Available Models")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(8)
                            .background(Color(.textBackgroundColor).opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        // Show available models
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(aiService.availableOllamaModels) { model in
                                    Text(model.name)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(ollamaModelName == model.name ? 
                                                      Color.blue.opacity(0.2) : 
                                                      Color(.textBackgroundColor).opacity(0.1))
                                        )
                                        .onTapGesture {
                                            ollamaModelName = model.name
                                            updateSettings()
                                            print("Selected model from list: \(model.name)")
                                        }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            } else {
                TextField("Model Name", text: $ollamaModelName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: ollamaModelName) { _, _ in
                        updateSettings()
                    }
            }
            
            Text("Use the AI model name, e.g., gemma3:4b, llama3, etc.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Refresh Ollama models
    private func refreshOllamaModels() {
        Task {
            isRefreshingModels = true
            print("Refreshing Ollama models...")
            
            // Force refresh by creating a new temporary settings object
            let tempSettings = AppSettings(
                ollamaServerAddress: ollamaServerAddress,
                ollamaServerPort: ollamaServerPort,
                useLocalOllama: true
            )
            aiService.updateConfig(settings: tempSettings)
            
            // Fetch models
            await aiService.fetchOllamaModels()
            
            // Update model name if models were found
            if let firstModel = aiService.availableOllamaModels.first {
                ollamaModelName = firstModel.name
                updateSettings()
                print("Selected first model: \(firstModel.name)")
            } else {
                print("No models found after refresh")
                
                // Try running a direct command to list models
                print("Available models from aiService: \(aiService.availableOllamaModels.map { $0.name }.joined(separator: ", "))")
            }
            
            isRefreshingModels = false
        }
    }
    
    // Azure OpenAI settings view
    private var azureSettingsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Azure OpenAI settings
            Text("Azure Endpoint:")
            TextField("https://your-resource-name.openai.azure.com", text: $azureEndpoint)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: azureEndpoint) { _, _ in
                    updateSettings()
                }
            
            Text("Deployment Name:")
            TextField("your-deployment-name", text: $azureDeploymentName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: azureDeploymentName) { _, _ in
                    updateSettings()
                }
            
            Text("API Version:")
            TextField("2023-05-15", text: $azureAPIVersion)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: azureAPIVersion) { _, _ in
                    updateSettings()
                }
            
            Text("API Key:")
            SecureField("API Key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: apiKey) { _, _ in
                    updateSettings()
                }
        }
    }
    
    // General API settings view
    private var generalAPISettingsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // General API settings
            Text("Model Name:")
            TextField("Model Name", text: $apiModelName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: apiModelName) { _, _ in
                    updateSettings()
                }
            
            Text("API Key:")
            SecureField("API Key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: apiKey) { _, _ in
                    updateSettings()
                }
            
            Text("Using \(selectedAPIProvider.baseURL)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Initialize values from settings
    private func initializeFromSettings() {
        selectedAPIProvider = settings.effectiveAPIProvider
        apiModelName = settings.effectiveAPIModelName
        apiKey = settings.effectiveAPIKey
        
        // Ollama API settings
        ollamaServerAddress = settings.effectiveOllamaServerAddress
        ollamaServerPort = settings.effectiveOllamaServerPort
        useLocalOllama = settings.effectiveUseLocalOllama
        ollamaModelName = settings.effectiveOllamaModelName
        ollamaAPIKey = settings.effectiveOllamaAPIKey
        
        // Azure API settings
        azureEndpoint = settings.effectiveAzureEndpoint
        azureDeploymentName = settings.effectiveAzureDeploymentName
        azureAPIVersion = settings.effectiveAzureAPIVersion
        
        // Update AIService with current settings
        aiService.updateConfig(settings: settings)
        
        // Fetch Ollama models if using local Ollama
        if selectedAPIProvider == .ollama && useLocalOllama {
            refreshOllamaModels()
        }
    }
    
    // Update settings with current values
    private func updateSettings() {
        settings.apiProvider = selectedAPIProvider.rawValue
        
        // Set the appropriate model name based on the provider
        if selectedAPIProvider == .ollama {
            settings.apiModelName = ollamaModelName
        } else {
            settings.apiModelName = apiModelName
        }
        
        // Set the appropriate API key based on the provider
        if selectedAPIProvider == .ollama && !useLocalOllama {
            settings.apiKey = ollamaAPIKey
        } else {
            settings.apiKey = apiKey
        }
        
        // Ollama API settings
        settings.ollamaServerAddress = ollamaServerAddress
        settings.ollamaServerPort = ollamaServerPort
        settings.useLocalOllama = useLocalOllama
        settings.ollamaModelName = ollamaModelName
        settings.ollamaAPIKey = ollamaAPIKey
        
        // Azure API settings
        settings.azureEndpoint = azureEndpoint
        settings.azureDeploymentName = azureDeploymentName
        settings.azureAPIVersion = azureAPIVersion
        
        // Update AIService with current settings
        aiService.updateConfig(settings: settings)
    }
}

struct APISettingsView_Previews: PreviewProvider {
    static var previews: some View {
        APISettingsView(
            settings: .constant(AppSettings())
        )
        .padding()
    }
}