# 宠标通 · PetFeedCheck

宠物食品标签智能合规审核 — iOS / iPadOS / visionOS App

## 技术栈

- **框架**: SwiftUI（iOS 17+ / iPadOS 17+ / visionOS 1.0+）
- **架构**: MVVM（`AuditViewModel` 驱动所有状态）
- **后端**: Flask REST API（`pet-feed-backend`）
- **配色**: 暖橙金色系（#F59E0B / #D97706 / #B45309）

## 项目结构

```
newwork/
├── project.yml                  # XcodeGen 项目描述文件
├── PetFeedCheck/
│   ├── PetFeedCheckApp.swift    # @main 入口
│   ├── Models/
│   │   ├── AuditModels.swift    # 数据模型
│   │   └── APIService.swift     # 网络请求层
│   ├── ViewModels/
│   │   └── AuditViewModel.swift # 核心状态管理
│   ├── Views/
│   │   ├── ContentView.swift    # 主界面
│   │   ├── ImageThumbnailCell.swift  # 图片单元格
│   │   ├── ModelPickerView.swift     # 模型选择器
│   │   ├── AuditResultView.swift     # 审核结果
│   │   └── SettingsView.swift        # 设置页
│   └── Utilities/
│       ├── ColorTheme.swift     # 配色常量
│       └── MarkdownParser.swift # Markdown 解析
└── README.md
```

## 如何打开项目

### 方式一：使用 XcodeGen（推荐）

```bash
# 1. 安装 XcodeGen
brew install xcodegen

# 2. 在 newwork 目录下生成 Xcode 项目
cd newwork
xcodegen generate

# 3. 打开项目
open PetFeedCheck.xcodeproj
```

### 方式二：手动创建 Xcode 项目

1. 打开 Xcode → File → New → Project → iOS → App
2. Product Name: `PetFeedCheck`, Interface: `SwiftUI`, Language: `Swift`
3. 保存到 `newwork/` 目录
4. 将 `PetFeedCheck/` 下的所有 `.swift` 文件拖入 Xcode 项目
5. 确保 Deployment Target 设置为 iOS 17.0

## 配置

App 首次启动后，进入设置页（右上角齿轮图标），配置：

| 配置项 | 说明 |
|---|---|
| 后端地址 | Flask 后端部署后的公网 URL |
| LLM Token | SiliconFlow API Key |
| OCR Token | Baidu AIStudio Token |

也可通过修改 `APIService.swift` 中的默认值来预设。

## 功能清单

- 多图选择与拖拽排序
- 5 款 AI 模型自由切换
- 异步审核 + 实时轮询
- Markdown 原生渲染结果
- 结果复制与分享
- 后端地址与 Token 配置管理
- 支持 iOS / iPadOS / visionOS 自适应布局

## 与后端的对接

本 App 默认通过 `POST /api/audit`（传 base64 图片数据）直接提交审核，后端须部署到公网可访问的地址。

后端代码位于: `../pet-feed-backend/`
