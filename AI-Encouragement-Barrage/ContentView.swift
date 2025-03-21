//
//  ContentView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/20.
//

import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var context: String = ""
    @State private var aiService: AIService?
    @State private var barrageService: BarrageService?
    @State private var reason: String = ""
    @State private var location: String = ""
    @State private var activity: String = ""
    @State private var feeling: String = "很好"
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("AI 弹幕助手")
                .font(.title)
                .padding()
            
            // 打印当前上下文（调试用）
            Text("") // 空Text，不显示
                .onAppear {
                    print("ContentView: currentContext = \(appState.currentContext)")
                }
            
            // 输入表单
            Group {
                TextField("因为什么原因", text: $reason)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(appState.isProcessing)
                
                TextField("在什么地点", text: $location)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(appState.isProcessing)
                
                TextField("做什么事情", text: $activity)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(appState.isProcessing)
                
                // 感觉选择器
                Picker("感觉如何", selection: $feeling) {
                    Text("很好").tag("很好")
                    Text("一般").tag("一般")
                    Text("不好").tag("不好")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            HStack(spacing: 15) {
                // 提交按钮
                Button(action: {
                    Task {
                        // 构建上下文字符串
                        let newContext = "因为\(reason)我在\(location)做\(activity)，我感觉\(feeling)"
                        await appState.setContext(newContext)
                    }
                }) {
                    if appState.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("生成弹幕")
                    }
                }
                .disabled((reason.isEmpty || location.isEmpty || activity.isEmpty) || appState.isProcessing)
                .buttonStyle(.borderedProminent)
                
                // 开关按钮
                Button(action: {
                    appState.toggleBarrage()
                }) {
                    HStack {
                        Image(systemName: appState.isBarrageActive ? "pause.circle.fill" : "play.circle.fill")
                        Text(appState.isBarrageActive ? "停止弹幕" : "开始弹幕")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.currentContext.isEmpty)
                .tint(appState.isBarrageActive ? .red : .green)
            }
            .padding(.horizontal)
            
            // 状态提示
            if appState.currentContext.isEmpty {
                Text("请先输入你正在做什么，然后生成弹幕")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("当前上下文: \(appState.currentContext)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            Spacer()
        }
        .frame(width: 400, height: 250)
        .onAppear {
            initializeServices()
        }
    }
    
    private func initializeServices() {
        // 创建弹幕服务
        barrageService = BarrageService(appState: appState)
        
        // 创建AI服务
        aiService = AIService(settings: AppSettings())
        
        // 将服务注入AppState
        if let barrageService = barrageService,
           let aiService = aiService {
            Task { @MainActor in
                appState.initialize(barrageService: barrageService, aiService: aiService)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
