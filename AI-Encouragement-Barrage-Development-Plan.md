# AI Encouragement Barrage 项目全景文档

## 项目概述
AI Encouragement Barrage 是一个基于 Swift 的应用程序，旨在提供鼓励和支持的消息。该项目采用 MVVM 架构，分为多个模块，包括服务层、模型层、视图层和视图模型。

## 目录结构
```
AI-Encouragement-Barrage/
├── .gitignore
├── AI-Encouragement-Barrage-Development-Plan.md
├── README.md
├── ScreenCaptureKit-Migration.md
├── AI-Encouragement-Barrage/
│   ├── AI_Encouragement_Barrage.entitlements
│   ├── AI_Encouragement_BarrageApp.swift
│   ├── ContentView.swift
│   ├── Info.plist
│   ├── Assets.xcassets/
│   ├── Models/
│   ├── Services/
│   ├── Views/
│   └── ViewModels/
├── Config/
│   └── APIConfig.swift
├── Utils/
│   └── KeychainManager.swift
├── AI-Encouragement-BarrageTests/
│   └── AI_Encouragement_BarrageTests.swift
└── AI-Encouragement-BarrageUITests/
    └── AI_Encouragement_BarrageUITests.swift
```

## 模块说明
- **服务层 (Services)**: 处理与外部 API 的交互，包含多个服务实现。
- **模型层 (Models)**: 定义数据模型和错误处理。
- **视图层 (Views)**: 使用 SwiftUI 构建用户界面。
- **视图模型 (ViewModels)**: 处理业务逻辑和状态管理。

## 架构优化
1. **服务层抽象**:
   - 创建 `AIServiceProtocol` 协议，统一不同 AI 服务的接口
   - 实现工厂模式 `AIServiceFactory` 创建具体服务实例
   - 将具体服务实现（Ollama、Azure、LM Studio）与主服务解耦

2. **依赖注入**:
   - 使用协议而非具体类型作为依赖
   - 通过工厂方法创建服务实例
   - 简化测试和模拟

3. **错误处理统一**:
   - 使用 `AIServiceError` 枚举统一错误处理
   - 提供本地化错误描述

4. **代码复用**:
   - 抽取共享功能到基类或扩展
   - 减少重复代码

## 未来工作
1. **单元测试**:
   - 为核心服务添加单元测试
   - 使用协议模拟依赖

2. **性能优化**:
   - 优化图像处理
   - 改进内存管理

3. **功能扩展**:
   - 支持更多 AI 服务提供商
   - 增强弹幕显示效果

4. **文档完善**:
   - 添加代码注释
   - 更新开发文档