//
//  AIService.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import Foundation

/// AI服务 - 负责生成鼓励性文本
class AIService {
    private let settings: AppSettings
    
    init(settings: AppSettings) {
        self.settings = settings
    }
    
    /// 分析文本并生成鼓励性回应
        /// - Parameter text: 用户输入的文本
        /// - Returns: 生成的鼓励性文本
        func analyzeText(text: String) async throws -> String {
            // 使用提示词构建请求
            let prompt = """
            你是一个桌面助手。请根据用户的输入生成100条简短、积极、鼓励的弹幕消息。
            每条消息不超过20个字符，每条消息占一行。
            
            用户输入: \(text)
            
            请用不同的表达方式生成鼓励性的弹幕消息，确保消息多样化且与用户输入相关。
            """
            
            // 发送请求到API
            let apiProvider = APIProvider(rawValue: settings.apiProvider) ?? .ollama
            let modelName = settings.effectiveAPIModelName
            let apiKey = settings.effectiveAPIKey
            
            // 这里简化为模拟响应，实际项目中需要实现真实的API调用
            // TODO: 实现真实的API调用
            let mockResponses = generateMockBarrages(context: text, count: 100)
            
            // 模拟网络延迟
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            return mockResponses.joined(separator: "\n")
        }
        
        /// 生成模拟弹幕
        /// - Parameters:
        ///   - context: 上下文
        ///   - count: 生成数量
        /// - Returns: 弹幕数组
        private func generateMockBarrages(context: String, count: Int) -> [String] {
            // 解析上下文
            var reason = ""
            var location = ""
            var activity = ""
            var feeling = "很好"
            
            // 解析"因为{理由}我在{地点}做{什么事}，我感觉{选项}"格式
            if context.starts(with: "因为") {
                let parts = context.components(separatedBy: "我在")
                if parts.count > 1 {
                    reason = parts[0].replacingOccurrences(of: "因为", with: "")
                    
                    let locationParts = parts[1].components(separatedBy: "做")
                    if locationParts.count > 1 {
                        location = locationParts[0]
                        
                        let activityParts = locationParts[1].components(separatedBy: "，我感觉")
                        if activityParts.count > 1 {
                            activity = activityParts[0]
                            feeling = activityParts[1]
                        } else {
                            activity = locationParts[1]
                        }
                    }
                }
            }
            
            // 根据感觉选择不同的基础响应
            var baseResponses: [String] = []
            
            // 通用响应
            let commonResponses = [
                "继续加油！",
                "你很棒！",
                "坚持下去！",
                "不要放弃！",
                "相信自己！"
            ]
            
            // 根据感觉添加特定响应
            if feeling == "很好" {
                baseResponses += [
                    "太棒了！继续保持！",
                    "你的状态真不错！",
                    "这种感觉真好！",
                    "享受这美好时光！",
                    "你做得非常出色！",
                    "保持这种状态！",
                    "你真是太厉害了！",
                    "这就是成功的感觉！",
                    "你的努力得到了回报！",
                    "继续闪耀吧！"
                ]
            } else if feeling == "一般" {
                baseResponses += [
                    "坚持就会有进步！",
                    "每一步都很重要！",
                    "稳步前进中！",
                    "保持节奏，会更好的！",
                    "平稳前进也是成功！",
                    "慢慢来，会变得更好！",
                    "保持耐心，继续努力！",
                    "稳定的过程也很珍贵！",
                    "不急不躁，稳步向前！",
                    "平静中蕴含力量！"
                ]
            } else if feeling == "不好" {
                baseResponses += [
                    "挑战总会过去的！",
                    "困难只是暂时的！",
                    "坚持住，会好起来的！",
                    "相信明天会更好！",
                    "每个低谷后都是上升！",
                    "不要放弃，你能行！",
                    "暴风雨后就是彩虹！",
                    "这只是成功路上的一小步！",
                    "调整心态，重新出发！",
                    "困难让你更强大！"
                ]
            }
            
            // 根据活动添加特定响应
            if !activity.isEmpty {
                baseResponses += [
                    "\(activity)需要耐心！",
                    "专注\(activity)，你会成功！",
                    "\(activity)中的每一步都很重要！",
                    "你在\(activity)方面很有天赋！",
                    "\(activity)让你与众不同！"
                ]
            }
            
            // 根据地点添加特定响应
            if !location.isEmpty {
                baseResponses += [
                    "\(location)是个好地方！",
                    "在\(location)的每一刻都很珍贵！",
                    "\(location)见证你的成长！",
                    "\(location)充满可能性！",
                    "\(location)是你展示才华的舞台！"
                ]
            }
            
            // 根据理由添加特定响应
            if !reason.isEmpty {
                baseResponses += [
                    "\(reason)是个好动力！",
                    "因为\(reason)，你更加出色！",
                    "\(reason)让你与众不同！",
                    "\(reason)是你前进的动力！",
                    "\(reason)证明你很有决心！"
                ]
            }
            
            // 如果没有足够的特定响应，添加通用响应
            if baseResponses.isEmpty {
                baseResponses = commonResponses
            } else {
                baseResponses += commonResponses
            }
            
            var results: [String] = []
            
            // 生成指定数量的弹幕
            for _ in 0..<count {
                if let base = baseResponses.randomElement() {
                    results.append(base)
                }
            }
            
            return results
    }
}
