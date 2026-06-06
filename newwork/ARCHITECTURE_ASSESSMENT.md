# 宠标通 · PetFeedCheck — 架构评估与迁移方案

## 1. 现状分析

### 1.1 后端 (pet-feed-backend) — ✅ 已基本完善

| 组件 | 文件 | 状态 |
|------|------|------|
| Flask 入口 | app.py | ✅ 完成 |
| 配置管理 | config.py | ✅ 环境变量驱动 |
| 请求路由 | Function_Management.py | ✅ 异步任务模式 |
| OCR 引擎 | Paddle_OCR.py | ✅ 百度 AIStudio |
| LLM 调用 | LLM_Judge.py | ✅ SiliconFlow API |
| RAG 法规库 | Text_Check.py | ✅ FAISS + Embedding |
| 审核编排 | Pet_Feed.py | ✅ OCR → RAG → LLM |
| 容器化 | Dockerfile | ✅ 已有 |
| 依赖 | requirements.txt | ✅ 完整 |

**审核流程**: 图片 → OCR → RAG检索法规 → LLM合规判断 → 结构化输出

### 1.2 原前端 (微信小程序) — ⚠️ 需替换

原代码位于 miniprogram/ 目录，是完整的微信小程序，使用:
- `wx.chooseMedia` 选图
- `wx.cloud.uploadFile` / 直连 Flask 上传
- 轮询 `GET /api/task/<task_id>` 获取结果
- 自定义 Markdown 解析渲染

这些能力需要在 iOS 中用原生 SwiftUI / UIKit 等价物替换。

### 1.3 新前端 (newwork) — ⚠️ 仅有项目骨架

newwork/ 目录当前仅有:
- `project.yml` (XcodeGen 描述文件)
- `README.md` (项目说明)

缺少全部 Swift 源文件 → **已在本轮补齐**.

## 2. 架构对比

```
微信小程序架构:
┌──────────┐     ┌──────────────┐     ┌──────────┐
│ 微信客户端 │────▶│ 微信云托管     │────▶│ AI 后端   │
│ (WXML)   │     │ (容器化 Flask) │     │ (OCR/LLM) │
└──────────┘     └──────────────┘     └──────────┘

iOS App 架构:
┌──────────┐     ┌──────────────┐     ┌──────────┐
│ iOS App  │────▶│ 阿里云 ECS    │────▶│ AI 后端   │
│ (SwiftUI)│     │ (Docker)     │     │ (OCR/LLM) │
└──────────┘     └──────────────┘     └──────────┘
```

## 3. iOS App 能力对照

| 微信小程序功能 | iOS SwiftUI 实现 |
|---------------|-----------------|
| wx.chooseMedia (选图) | PhotosPicker (iOS 17+) |
| wx.cloud.uploadFile (上传) | URLSession POST /api/audit (base64) |
| 图片拖拽排序 | onMove + List move (已实现) |
| wx.request 轮询 | async/await + Task.sleep 轮询 |
| Markdown 渲染 | MarkdownParser → AuditResultView |
| wx.setClipboardData | UIPasteboard |
| wx.showModal | SwiftUI Alert / Sheet |
| 模型选择 | ModelPickerView (List) |
| 设置 (Token/URL) | SettingsView (Form + SecureField) |

## 4. 后端迁移到阿里云的改动

### 4.1 需要修改的点

1. **移除微信云托管特定配置**: `container.config.json` 是微信云托管专用，阿里云 ECS 不需要
2. **健康检查**: 已有 `/api/health`，满足负载均衡需求
3. **日志输出**: 原输出到 stdout (gunicorn access-logfile)，ECS 上可配合阿里云 SLS
4. **环境变量**: OCR_TOKEN, LLM_TOKEN 通过 ECS 环境变量或 .env 注入
5. **静态文件**: `temp_images/` 和 `tasks/` 建议迁移到 OSS（可选，小规模直接用本地磁盘）
6. **安全组**: ECS 安全组需开放 80/443 端口

### 4.2 新增文件

- `docker-compose.yml` — 单机部署
- `.env.example` — 环境变量模板
- `deploy/nginx.conf` — Nginx 反向代理 (可选)
- `deploy/ecs-setup.sh` — ECS 初始化脚本

## 5. GitHub Actions CI/CD

### 5.1 Windows 编译 iOS App 的限制

**关键事实**: 在 Windows 上用 GitHub Actions 编译 iOS `.ipa` 是**不可能的**，因为:
- Xcode 和 xcodebuild 仅存在于 macOS
- iOS SDK 仅存在于 macOS
- 代码签名需要 Keychain (macOS)

### 5.2 可行方案

| 方案 | 描述 | 推荐度 |
|------|------|--------|
| **macOS Runner** | GitHub Actions `macos-latest` runner | ⭐⭐⭐ 推荐 |
| Mac Mini 本地 | 本地 Mac + self-hosted runner | ⭐⭐ |
| Windows 交叉编译 | Swift toolchain on Windows 可编译但不能签名 | ⭐ (仅验证编译) |

### 5.3 推荐工作流

```yaml
on: push
jobs:
  build:
    runs-on: macos-latest  # 必须 macOS
    steps:
      - checkout
      - xcodegen generate (从 project.yml)
      - xcodebuild archive
      - upload .ipa artifact
```

如果必须用 Windows，可以:
- 用 Windows runner 做 lint / test / backend CI
- iOS 编译仍需 macOS runner
- 分开两个 workflow，或只在 release 时才编译 iOS

## 6. 建议的目录结构

```
Pet_Feed_Check (2)/
├── newwork/                    # iOS App
│   ├── project.yml
│   ├── PetFeedCheck/
│   │   ├── PetFeedCheckApp.swift
│   │   ├── Info.plist
│   │   ├── Models/
│   │   │   ├── AuditModels.swift
│   │   │   └── APIService.swift
│   │   ├── ViewModels/
│   │   │   └── AuditViewModel.swift
│   │   ├── Views/
│   │   │   ├── ContentView.swift
│   │   │   ├── ImageThumbnailCell.swift
│   │   │   ├── ModelPickerView.swift
│   │   │   ├── AuditResultView.swift
│   │   │   └── SettingsView.swift
│   │   └── Utilities/
│   │       ├── ColorTheme.swift
│   │       └── MarkdownParser.swift
│   └── README.md
├── pet-feed-backend/           # Flask 后端
│   ├── app.py
│   ├── config.py
│   ├── Dockerfile
│   ├── docker-compose.yml      # [新增]
│   ├── .env.example            # [新增]
│   └── deploy/                 # [新增]
│       ├── nginx.conf
│       └── ecs-setup.sh
└── .github/workflows/          # CI/CD
    ├── ios-build.yml           # [新增] macOS runner
    └── backend-deploy.yml      # [新增] 部署到阿里云
```
