//
//  AIServiceModels.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation

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

// LM Studio model structure
struct LMStudioModel: Identifiable, Hashable {
    let id: String
    let created: String
    let owned_by: String
    
    var displayName: String {
        return id
    }
}