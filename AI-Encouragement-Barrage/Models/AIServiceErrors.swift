//
//  AIServiceErrors.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation

// Error types for AI services
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