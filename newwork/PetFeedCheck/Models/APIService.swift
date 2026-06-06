import Foundation

actor APIService {
    static let shared = APIService()

    private var baseURL: String {
        get {
            if let data = UserDefaults.standard.data(forKey: AppSettings.storageKey),
               let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
                return settings.backendURL
            }
            return "https://your-server.com"
        }
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 180
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    // MARK: - Health Check

    func healthCheck() async throws -> HealthResponse {
        let url = URL(string: "\(baseURL)/api/health")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }

    // MARK: - Submit Audit (base64 images)

    func submitAudit(images: [Data], model: String, level: Int = 3) async throws -> String {
        let url = URL(string: "\(baseURL)/api/audit")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 30

        let base64Images = images.map { $0.base64EncodedString() }
        let body = AuditRequest(images: base64Images, model: model, level: level)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        let result = try JSONDecoder().decode(AuditSubmitResponse.self, from: data)
        guard result.success, let taskInfo = result.data else {
            throw APIError.requestFailed(message: result.message ?? "提交失败")
        }
        return taskInfo.taskId
    }

    // MARK: - Poll Task Status

    func pollTask(taskId: String) async throws -> TaskPollResult {
        let url = URL(string: "\(baseURL)/api/task/\(taskId)")!
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError(statusCode: 0)
        }

        if httpResponse.statusCode == 404 {
            throw APIError.taskNotFound
        }

        let result = try JSONDecoder().decode(TaskStatusResponse.self, from: data)

        if let taskData = result.data {
            switch taskData.status {
            case "completed":
                return .completed(result: taskData.result ?? "")
            case "failed":
                throw APIError.auditFailed(message: result.message ?? "审核失败")
            default:
                return .processing(status: taskData.status)
            }
        } else if !(result.success) {
            throw APIError.auditFailed(message: result.message ?? "请求失败")
        }

        return .processing(status: "pending")
    }
}

// MARK: - Poll Result

enum TaskPollResult {
    case processing(status: String)
    case completed(result: String)
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case serverError(statusCode: Int)
    case requestFailed(message: String)
    case taskNotFound
    case auditFailed(message: String)

    var errorDescription: String? {
        switch self {
        case .serverError(let code): return "服务器错误 (HTTP \(code))"
        case .requestFailed(let msg): return msg
        case .taskNotFound: return "任务不存在或已过期"
        case .auditFailed(let msg): return msg
        }
    }
}
