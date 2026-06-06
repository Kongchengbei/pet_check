import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var vm = AuditViewModel()
    @State private var selectedPickerItems: [PhotosPickerItem] = []
    @State private var replacePickerItem: PhotosPickerItem?
    @State private var replaceIndex: Int?
    @State private var viewID = 0

    var body: some View {
        NavigationStack {
            ZStack {
                PetColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        topIllustration
                        imageUploadPanel
                        modelSelectionPanel
                        quickActionsPanel
                        submitButton
                        if vm.auditState.isCompleted || vm.auditState.isFailed || !vm.parsedNodes.isEmpty {
                            resultPanel
                        }
                        footer
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("宠标速鉴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(PetColors.primaryDark)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(PetColors.surfaceLight, for: .navigationBar)
            .sheet(isPresented: $vm.showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $vm.showModelPicker) {
                ModelPickerView(selectedModel: $vm.selectedModel)
            }
            .onChange(of: selectedPickerItems) { _, items in
                Task { await vm.addImages(items) }
                selectedPickerItems = []
            }
            .onChange(of: replacePickerItem) { _, item in
                guard let item, let idx = replaceIndex else { return }
                Task { await vm.replaceImage(at: idx, with: item) }
                replacePickerItem = nil
                replaceIndex = nil
            }
            .alert("删除图片", isPresented: $vm.showDeleteAlert) {
                Button("取消", role: .cancel) { vm.showDeleteAlert = false }
                Button("删除", role: .destructive) { vm.performDelete() }
            } message: {
                Text("确定要删除这张图片吗？删除后将无法恢复。")
            }
        }
    }

    // MARK: - Top Illustration

    private var topIllustration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [PetColors.primaryLight.opacity(0.6), PetColors.surfaceLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .top) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(PetColors.primary.opacity(0.4))
                        .padding(.top, 16)
                }

            VStack(spacing: 8) {
                Spacer().frame(height: 80)
                Text("宠物食品标签")
                    .font(.title2.bold())
                    .foregroundColor(PetColors.textPrimary)
                Text("智能合规审核")
                    .font(.subheadline)
                    .foregroundColor(PetColors.textSecondary)
            }
            .padding(.bottom, 20)
        }
        .frame(height: 140)
    }

    // MARK: - Image Upload Panel

    private var imageUploadPanel: some View {
        PanelCard(icon: "photo.on.rectangle.angled", iconColor: PetColors.primary, title: "上传宠粮图片", subtitle: "支持多图批量分析") {
            VStack(spacing: 12) {
                if vm.selectedImages.isEmpty {
                    emptyUploadArea
                } else if vm.selectedImages.count == 1 {
                    singleImageMode
                } else {
                    multiImageGrid
                }
            }
        }
    }

    private var emptyUploadArea: some View {
        PhotosPicker(selection: $selectedPickerItems, maxSelectionCount: vm.maxImages, matching: .images) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(PetColors.primaryLight, lineWidth: 2)
                        .frame(width: 80, height: 80)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32))
                        .foregroundColor(PetColors.primary)
                }
                Text("点击上传图片")
                    .font(.headline)
                    .foregroundColor(PetColors.textPrimary)
                Text("最多 \(vm.maxImages) 张，支持相册和拍照")
                    .font(.caption)
                    .foregroundColor(PetColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }

    private var singleImageMode: some View {
        VStack(spacing: 10) {
            if let image = vm.selectedImages.first,
               let uiImage = UIImage(data: image.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            HStack(spacing: 12) {
                PhotosPicker(selection: Binding(
                    get: { [] },
                    set: { items in
                        if let first = items.first {
                            replacePickerItem = first
                            replaceIndex = 0
                        }
                    }
                ), matching: .images) {
                    Label("更换", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(PetColors.primaryLight.opacity(0.3))
                        .foregroundColor(PetColors.primaryDark)
                        .clipShape(Capsule())
                }

                Button { vm.confirmDelete(at: 0) } label: {
                    Label("删除", systemImage: "trash")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .clipShape(Capsule())
                }

                PhotosPicker(selection: $selectedPickerItems, maxSelectionCount: vm.maxImages - vm.selectedImages.count, matching: .images) {
                    Label("继续添加", systemImage: "plus")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(PetColors.primary.opacity(0.15))
                        .foregroundColor(PetColors.primaryDark)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var multiImageGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        let totalItems = vm.selectedImages.count + (vm.selectedImages.count < vm.maxImages ? 1 : 0)

        return LazyVGrid(columns: totalItems <= 4 ? Array(columns.prefix(2)) : columns, spacing: 8) {
            ForEach(Array(vm.selectedImages.enumerated()), id: \.element.id) { index, item in
                ImageThumbnailCell(
                    imageData: item.data,
                    onDelete: { vm.confirmDelete(at: index) },
                    onTap: {
                        replaceIndex = index
                    }
                )
            }

            if vm.selectedImages.count < vm.maxImages {
                PhotosPicker(selection: $selectedPickerItems, maxSelectionCount: vm.maxImages - vm.selectedImages.count, matching: .images) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(PetColors.border.opacity(0.5))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(PetColors.textTertiary)
                        )
                }
            }
        }
    }

    // MARK: - Model Selection

    private var modelSelectionPanel: some View {
        PanelCard(icon: "cpu", iconColor: PetColors.primaryDark, title: "选择审核模型", subtitle: "按速度和效果自由切换") {
            Button { vm.showModelPicker = true } label: {
                HStack {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(PetColors.primary.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(vm.selectedModel.displayName.prefix(1)))
                                    .font(.headline.bold())
                                    .foregroundColor(PetColors.primaryDark)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vm.selectedModel.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(PetColors.textPrimary)
                            Text(vm.selectedModel.description)
                                .font(.caption)
                                .foregroundColor(PetColors.textSecondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(PetColors.textTertiary)
                }
                .padding(12)
                .background(PetColors.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActionsPanel: some View {
        PanelCard(icon: "bolt.fill", iconColor: PetColors.warning, title: "快速审核", subtitle: "一键切换常用模型") {
            HStack(spacing: 10) {
                ForEach([ModelOption.available[0], ModelOption.available[2]]) { model in
                    Button {
                        vm.selectedModel = model
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(vm.selectedModel.id == model.id ? PetColors.primary : PetColors.border.opacity(0.5))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(String(model.name.prefix(1)))
                                        .font(.headline.bold())
                                        .foregroundColor(vm.selectedModel.id == model.id ? .white : PetColors.textSecondary)
                                )
                            Text(model.displayName)
                                .font(.caption2.weight(.medium))
                                .foregroundColor(vm.selectedModel.id == model.id ? PetColors.primaryDark : PetColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            vm.selectedModel.id == model.id
                                ? PetColors.primary.opacity(0.08)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            vm.startAudit()
        } label: {
            HStack(spacing: 8) {
                if vm.isLoading {
                    ProgressView()
                        .tint(.white)
                    Text("审核中...")
                        .font(.headline)
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.headline)
                    Text("立即审核")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                vm.isLoading
                    ? LinearGradient(colors: [PetColors.primaryLight, PetColors.primary], startPoint: .leading, endPoint: .trailing).opacity(0.7)
                    : LinearGradient(colors: [PetColors.primary, PetColors.primaryDark], startPoint: .leading, endPoint: .trailing)
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(vm.selectedImages.isEmpty || vm.isLoading)
        .opacity(vm.selectedImages.isEmpty ? 0.6 : 1.0)
    }

    // MARK: - Result Panel

    private var resultPanel: some View {
        PanelCard(icon: "doc.text.fill", iconColor: PetColors.success, title: "审核结果", subtitle: vm.selectedModel.displayName) {
            VStack(spacing: 12) {
                AuditResultView(nodes: vm.parsedNodes)

                HStack(spacing: 12) {
                    Button { vm.copyToClipboard() } label: {
                        Label("复制结果", systemImage: "doc.on.doc")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(PetColors.background)
                            .foregroundColor(PetColors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    ShareLink(item: vm.rawMarkdown) {
                        Label("分享结果", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(PetColors.primary.opacity(0.1))
                            .foregroundColor(PetColors.primaryDark)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Text("结果仅供参考，请结合实际喂养场景判断")
            .font(.caption2)
            .foregroundColor(PetColors.textTertiary)
            .padding(.top, 4)
    }
}

// MARK: - AuditState Helpers

extension AuditState {
    var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

// MARK: - Panel Card

struct PanelCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 36, height: 36)
                    .background(iconColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(PetColors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(PetColors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().background(PetColors.border)

            content()
                .padding(16)
        }
        .background(PetColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let statusText: String
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("审核进行中")
                    .font(.title3.bold())
                    .foregroundColor(.white)

                Text(statusText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.0)
                            .animation(
                                .easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2),
                                value: true
                            )
                    }
                }

                Button("取消", action: onCancel)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 4)
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
        }
    }
}
