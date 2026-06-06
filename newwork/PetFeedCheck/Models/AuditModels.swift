import Foundation

// MARK: - Audit Request

struct AuditRequest: Codable {
    let images: [String]
    let model: String
    let level: Int
}

// MARK: - Audit Response (submit)

struct AuditSubmitResponse: Codable {
    let success: Bool
    let data: AuditTaskInfo?
    let message: String?
}

struct AuditTaskInfo: Codable {
    let taskId: String
    let status: String
}

// MARK: - Task Status Response (poll)

struct TaskStatusResponse: Codable {
    let success: Bool
    let data: TaskStatusData?
    let message: String?
}

struct TaskStatusData: Codable {
    let status: String
    let result: String?
}

// MARK: - Health Response

struct HealthResponse: Codable {
    let status: String
    let active_tasks: Int?
}

// MARK: - Model Option

struct ModelOption: Identifiable, Equatable {
    let id: String
    let name: String
    let displayName: String
    let description: String
    let apiModelName: String

    static let available: [ModelOption] = [
        ModelOption(
            id: "deepseek-r1",
            name: "DeepSeek-R1",
            displayName: "DeepSeek-R1",
            description: "推理能力强，适合复杂判断",
            apiModelName: "DeepSeek-R1"
        ),
        ModelOption(
            id: "deepseek-v3",
            name: "DeepSeek-V3.2",
            displayName: "DeepSeek-V3.2",
            description: "速度与效果均衡，日常首选",
            apiModelName: "DeepSeek-V3.2"
        ),
        ModelOption(
            id: "qwen3-next",
            name: "Qwen3-Next",
            displayName: "Qwen3-Next",
            description: "细节理解更强，图文分析稳定",
            apiModelName: "Qwen3-Next"
        ),
        ModelOption(
            id: "glm-4",
            name: "GLM-4.7",
            displayName: "GLM-4.7",
            description: "中文表现好，响应速度快",
            apiModelName: "GLM-4.7"
        ),
        ModelOption(
            id: "minimax-m2",
            name: "MiniMax-M2",
            displayName: "MiniMax-M2",
            description: "轻量高效，适合快速审核",
            apiModelName: "MiniMax-M2"
        )
    ]
}

// MARK: - Audit State

enum AuditState: Equatable {
    case idle
    case uploading
    case processing(statusText: String)
    case completed(result: String)
    case failed(error: String)
}

// MARK: - Parsed Markdown Node

struct MarkdownNode: Identifiable {
    let id = UUID()
    let type: MarkdownNodeType
    let content: String
    let language: String?
    let order: String?

    init(type: MarkdownNodeType, content: String, language: String? = nil, order: String? = nil) {
        self.type = type
        self.content = content
        self.language = language
        self.order = order
    }
}

enum MarkdownNodeType: String {
    case h1, h2, h3, h4
    case paragraph
    case boldParagraph
    case listItem
    case orderedItem
    case blockquote
    case codeBlock
    case horizontalRule
    case success
    case error
    case warning
    case info
}

// MARK: - User Settings

struct AppSettings: Codable {
    var backendURL: String = "https://your-server.com"
    var llmToken: String = ""
    var ocrToken: String = ""

    static let storageKey = "com.petfeedcheck.settings"
}

// MARK: - Image Item

struct ImageItem: Identifiable, Equatable {
    let id: String
    let data: Data

    init(data: Data) {
        self.id = UUID().uuidString
        self.data = data
    }

    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        lhs.id == rhs.id
    }
}
