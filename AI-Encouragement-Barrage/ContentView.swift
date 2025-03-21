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
    @StateObject private var settings = AppSettings()
    @State private var inputText: String = ""
    @State private var aiService: AIService?
    @State private var barrageService: BarrageService?
    @State private var showSettings: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("AI 弹幕助手")
                .font(.title)
                .padding()
            
            // 输入框
            TextField("输入你想要的弹幕内容", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(appState.isProcessing)
                .padding(.horizontal)
            
            HStack(spacing: 15) {
                // 生成弹幕按钮
                Button(action: {
                    Task {
                        await appState.setContext(inputText)
                    }
                }) {
                    if appState.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("生成弹幕")
                    }
                }
                .disabled(inputText.isEmpty || appState.isProcessing)
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
                
                // 设置按钮
                Button(action: {
                    showSettings.toggle()
                }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            
            // 状态提示
            if appState.currentContext.isEmpty {
                Text("请输入内容，然后生成弹幕")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("当前内容: \(appState.currentContext)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            // API设置区域
            if showSettings {
                VStack(alignment: .leading, spacing: 10) {
                    Text("API设置")
                        .font(.headline)
                    
                    // API提供者选择
                    Picker("API提供者", selection: $settings.apiProvider) {
                        ForEach(APIProvider.allCases, id: \.rawValue) { provider in
                            Text(provider.displayName).tag(provider.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    // 模型名称输入
                    HStack {
                        Text("模型名称:")
                        TextField(settings.effectiveAPIProvider.modelPlaceholder, text: $settings.apiModelName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // API密钥输入（仅当需要时显示）
                    if settings.currentProviderRequiresAPIKey {
                        HStack {
                            Text("API密钥:")
                            SecureField("输入API密钥", text: $settings.apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    // API测试按钮和结果
                    HStack {
                        Button(action: {
                            Task {
                                settings.isTesting = true
                                settings.testResult = "测试中..."
                                
                                if let aiService = aiService {
                                    let result = await aiService.testAPIConnection()
                                    settings.testResult = result
                                } else {
                                    settings.testResult = "错误: AI服务未初始化"
                                }
                                
                                settings.isTesting = false
                            }
                        }) {
                            if settings.isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("测试API连接")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(settings.isTesting)
                        
                        if !settings.testResult.isEmpty {
                            Text(settings.testResult)
                                .font(.caption)
                                .foregroundColor(settings.testResult.contains("错误") ? .red : .green)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(width: 400, height: showSettings ? 400 : 250)
        .animation(.easeInOut, value: showSettings)
        .onAppear {
            initializeServices()
        }
    }
    
    private func initializeServices() {
        // 创建弹幕服务
        barrageService = BarrageService(appState: appState)
        
        // 创建AI服务
        aiService = AIService(settings: settings)
        
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
