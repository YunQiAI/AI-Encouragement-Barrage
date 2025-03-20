//
//  BarrageSettingsView.swift
//  AI-Encouragement-Barrage
//
//  Created by YunQiAI on 2025/03/21.
//

import SwiftUI

/// 弹幕设置视图
struct BarrageSettingsView: View {
    @ObservedObject var barrageService: BarrageService
    @State private var config: BarrageConfig
    @State private var showPreview: Bool = false
    @State private var previewText: String = "这是一条测试弹幕，用于预览效果"
    
    init(barrageService: BarrageService) {
        self.barrageService = barrageService
        self._config = State(initialValue: barrageService.getBarrageConfig())
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 基本设置
                basicSettingsSection
                
                // 样式设置
                styleSettingsSection
                
                // 预览设置
                previewSection
                
                // 应用按钮
                applyButton
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    // 基本设置部分
    private var basicSettingsSection: some View {
        GroupBox(label: Text("基本设置").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                // 显示开关
                Toggle("显示弹幕", isOn: $barrageService.isVisible)
                    .padding(.bottom, 5)
                
                // 语音开关
                Toggle("启用语音朗读", isOn: $barrageService.speechEnabled)
                    .padding(.bottom, 10)
                
                // 弹幕速度
                HStack {
                    Text("弹幕速度:")
                    Slider(value: $config.speed, in: 0.2...3.0, step: 0.1)
                    Text("\(config.speed, specifier: "%.1f")x")
                        .frame(width: 40)
                }
                
                // 弹幕密度
                HStack {
                    Text("弹幕密度:")
                    Slider(value: $config.density, in: 1...20, step: 1)
                    Text("\(Int(config.density))/秒")
                        .frame(width: 50)
                }
                
                // 弹幕方向
                HStack {
                    Text("弹幕方向:")
                    Picker("", selection: $config.direction) {
                        ForEach(BarrageConfig.Direction.allCases) { direction in
                            Text(direction.rawValue).tag(direction)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 弹幕显示范围
                HStack {
                    Text("显示范围:")
                    Slider(value: $config.travelRange, in: 0.3...1.0, step: 0.1)
                    Text("\(Int(config.travelRange * 100))%")
                        .frame(width: 40)
                }
                
                // 弹幕存活时间
                HStack {
                    Text("存活时间:")
                    Slider(value: $config.lifetime, in: 3...15, step: 1)
                    Text("\(Int(config.lifetime))秒")
                        .frame(width: 40)
                }
            }
            .padding()
        }
    }
    
    // 样式设置部分
    private var styleSettingsSection: some View {
        GroupBox(label: Text("样式设置").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                // 预设样式
                HStack {
                    Text("预设样式:")
                    Picker("", selection: $config.defaultStyle) {
                        ForEach(BarrageConfig.StylePreset.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 随机样式
                Toggle("使用随机样式", isOn: $config.useRandomStyle)
                
                // 动画效果
                Toggle("启用动画效果", isOn: $config.enableAnimations)
            }
            .padding()
        }
    }
    
    // 预览部分
    private var previewSection: some View {
        GroupBox(label: Text("预览").font(.headline)) {
            VStack(alignment: .leading, spacing: 12) {
                // 预览文本输入
                TextField("预览文本", text: $previewText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // 预览按钮
                HStack {
                    Button("发送预览弹幕") {
                        barrageService.showBarrage(
                            text: previewText,
                            type: .normal,
                            speak: false,
                            saveToHistory: false
                        )
                    }
                    
                    Button("发送高亮弹幕") {
                        barrageService.showBarrage(
                            text: previewText,
                            type: .highlight,
                            speak: false,
                            saveToHistory: false
                        )
                    }
                    
                    Button("发送错误弹幕") {
                        barrageService.showBarrage(
                            text: previewText,
                            type: .error,
                            speak: false,
                            saveToHistory: false
                        )
                    }
                }
                
                // 清除按钮
                Button("清除所有弹幕") {
                    barrageService.clearAllBarrages()
                }
            }
            .padding()
        }
    }
    
    // 应用按钮
    private var applyButton: some View {
        HStack {
            Spacer()
            Button("应用设置") {
                barrageService.setBarrageConfig(config: config)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    let barrageService = BarrageService()
    return BarrageSettingsView(barrageService: barrageService)
}