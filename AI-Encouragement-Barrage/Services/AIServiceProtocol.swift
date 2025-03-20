//
//  AIServiceProtocol.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import Foundation
import CoreGraphics

/// 定义AI服务的通用协议，所有AI服务实现都应遵循此协议
protocol AIServiceProtocol {
    /// 发送请求到AI服务
    /// - Parameters:
    ///   - prompt: 提示词
    ///   - imageBase64: 可选的Base64编码图像
    ///   - useStreaming: 是否使用流式API（如果支持）
    ///   - streamHandler: 处理流式响应的回调
    /// - Returns: AI生成的响应文本
    /// - Throws: AIServiceError类型的错误
    func sendRequest(
        prompt: String,
        imageBase64: String?,
        useStreaming: Bool,
        streamHandler: ((String) -> Void)?
    ) async throws -> String
    
    /// 获取服务名称
    var serviceName: String { get }
    
    /// 获取当前使用的模型名称
    var currentModelName: String { get }
    
    /// 服务是否支持图像分析
    var supportsImageAnalysis: Bool { get }
    
    /// 服务是否支持流式响应
    var supportsStreaming: Bool { get }
}

/// 为协议提供默认实现
extension AIServiceProtocol {
    var supportsImageAnalysis: Bool {
        return true
    }
    
    var supportsStreaming: Bool {
        return false
    }
}