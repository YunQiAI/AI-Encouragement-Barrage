//
//  AIServiceErrors.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation

/// AI服务错误
enum AIServiceError: LocalizedError {
    case invalidInput
    case requestFailed
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "无效的输入内容"
        case .requestFailed:
            return "请求失败"
        case .networkError:
            return "网络连接错误"
        case .unknownError:
            return "未知错误"
        }
    }
}
