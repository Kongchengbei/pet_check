import SwiftUI
import PhotosUI

@MainActor
final class AuditViewModel: ObservableObject {

    // MARK: - Published State

    @Published var selectedImages: [ImageItem] = []
    @Published var selectedModel: ModelOption = ModelOption.available[0]
    @Published var auditState: AuditState = .idle
    @Published var parsedNodes: [MarkdownNode] = []
    @Published var rawMarkdown: String = ""
    @Published var showSettings: Bool = false
    @Published var showModelPicker: Bool = false
    @Published var showDeleteAlert: Bool = false
    @Published var deleteTargetIndex: Int = -1

    var maxImages: Int { 9 }
    var isLoading: Bool {
        if case .idle = auditState { return false }
        if case .completed = auditState { return false }
        if case .failed = auditState { return false }
        return true
    }

    private var pollingTask: Task<Void, Never>?

    // MARK: - Image Management

    func addImages(_ items: [PhotosPickerItem]) async {
        for item in items {
            if selectedImages.count >= maxImages { break }
            if let data = try? await item.loadTransferable(type: Data.self) {
                selectedImages.append(ImageItem(data: data))
            }
        }
    }

    func replaceImage(at index: Int, with item: PhotosPickerItem) async {
        guard index < selectedImages.count else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            selectedImages[index] = ImageItem(data: data)
        }
    }

    func moveImage(from source: IndexSet, to destination: Int) {
        selectedImages.move(fromOffsets: source, toOffset: destination)
    }

    func confirmDelete(at index: Int) {
        deleteTargetIndex = index
        showDeleteAlert = true
    }

    func performDelete() {
        guard deleteTargetIndex >= 0, deleteTargetIndex < selectedImages.count else { return }
        selectedImages.remove(at: deleteTargetIndex)
        if selectedImages.isEmpty {
            clearResults()
        }
        deleteTargetIndex = -1
        showDeleteAlert = false
    }

    func clearResults() {
        parsedNodes = []
        rawMarkdown = ""
        auditState = .idle
    }

    // MARK: - Audit Pipeline

    func startAudit() {
        guard !selectedImages.isEmpty else { return }
        pollingTask?.cancel()

        let modelName = selectedModel.apiModelName
        let images = selectedImages.map { $0.data }

        auditState = .uploading

        Task {
            do {
                let taskId = try await APIService.shared.submitAudit(
                    images: images,
                    model: modelName,
                    level: 3
                )
                await self.pollUntilComplete(taskId: taskId, modelName: selectedModel.displayName)
            } catch {
                auditState = .failed(error: error.localizedDescription)
            }
        }
    }

    private func pollUntilComplete(taskId: String, modelName: String) async {
        let maxDuration: TimeInterval = 180
        let pollInterval: TimeInterval = 7
        let startTime = Date()
        var secondsElapsed = 0

        while Date().timeIntervalSince(startTime) < maxDuration {
            secondsElapsed = Int(Date().timeIntervalSince(startTime))

            // Update status text with elapsed time
            if Task.isCancelled { break }

            let statusText = statusMessage(seconds: secondsElapsed, modelName: modelName)
            auditState = .processing(statusText: statusText)

            do {
                let result = try await APIService.shared.pollTask(taskId: taskId)
                switch result {
                case .completed(let markdown):
                    handleCompletedResult(markdown, modelName: modelName, imageCount: selectedImages.count)
                    return
                case .processing:
                    break // keep polling
                }
            } catch APIError.taskNotFound {
                auditState = .failed(error: "任务不存在或已过期")
                return
            } catch {
                // Non-fatal poll error; retry after interval
            }

            if Task.isCancelled { break }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval) * 1_000_000_000)
        }

        if !Task.isCancelled {
            auditState = .failed(error: "任务处理超时，请稍后重试")
        }
    }

    private func statusMessage(seconds: Int, modelName: String) -> String {
        switch seconds {
        case 0..<3: return "正在上传图片..."
        case 3..<8: return "正在创建任务..."
        case 8..<20: return "\(modelName) 分析中..."
        case 20..<40: return "处理中 \(seconds)s"
        case 40..<90: return "任务较复杂 \(seconds)s"
        default: return "请稍候 \(seconds)s"
        }
    }

    private func handleCompletedResult(_ markdown: String, modelName: String, imageCount: Int) {
        let now = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)

        let report = """
        # 宠粮审核报告

        ## 基本信息

        - 审核时间: \(now)
        - 使用模型: \(modelName)
        - 图片数量: \(imageCount) 张

        ---

        ## 审核结论

        \(markdown)

        ---

        > 报告由 \(modelName) 生成，仅供参考。
        """

        rawMarkdown = report
        parsedNodes = MarkdownParser.parse(report)
        auditState = .completed(result: markdown)
    }

    func cancelAudit() {
        pollingTask?.cancel()
        pollingTask = nil
        auditState = .idle
    }

    // MARK: - Share / Copy

    func copyToClipboard() {
        UIPasteboard.general.string = rawMarkdown
    }
}
