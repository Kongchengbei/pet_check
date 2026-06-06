import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var backendURL: String = "https://your-server.com"
    @State private var llmToken: String = ""
    @State private var ocrToken: String = ""
    @State private var showTokenWarning = false
    @State private var healthStatus: String?

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Backend URL
                Section {
                    TextField("https://your-server.com", text: $backendURL)
                        .font(.subheadline.monospaced())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } header: {
                    Label("后端地址", systemImage: "server.rack")
                } footer: {
                    Text("Flask 后端部署后的公网 URL，例如阿里云 ECS 公网 IP")
                }

                // MARK: Tokens
                Section {
                    SecureField("sk-xxxxxxxx", text: $llmToken)
                        .font(.subheadline.monospaced())
                    SecureField("xxxxxxxx", text: $ocrToken)
                        .font(.subheadline.monospaced())
                } header: {
                    Label("API Tokens", systemImage: "key.fill")
                } footer: {
                    Text("LLM Token: SiliconFlow API Key\nOCR Token: Baidu AIStudio Token")
                }

                // MARK: Health
                Section {
                    HStack {
                        Text("服务状态")
                        Spacer()
                        if let status = healthStatus {
                            Label(status, systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Button("检查连接") {
                                Task { await checkHealth() }
                            }
                            .font(.subheadline)
                        }
                    }
                } header: {
                    Label("连接测试", systemImage: "antenna.radiowaves.left.and.right")
                }

                // MARK: About
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("最低支持")
                        Spacer()
                        Text("iOS 17.0 / iPadOS 17.0 / visionOS 1.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("关于", systemImage: "info.circle")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { saveSettings() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { loadSettings() }
        }
    }

    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: AppSettings.storageKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return
        }
        backendURL = settings.backendURL
        llmToken = settings.llmToken
        ocrToken = settings.ocrToken
    }

    private func saveSettings() {
        guard !backendURL.isEmpty else { return }

        // Basic URL validation
        if !backendURL.hasPrefix("http://") && !backendURL.hasPrefix("https://") {
            backendURL = "https://" + backendURL
        }

        let settings = AppSettings(
            backendURL: backendURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")),
            llmToken: llmToken.trimmingCharacters(in: .whitespacesAndNewlines),
            ocrToken: ocrToken.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: AppSettings.storageKey)
        }
        dismiss()
    }

    private func checkHealth() async {
        do {
            let result = try await APIService.shared.healthCheck()
            await MainActor.run {
                healthStatus = result.status
            }
        } catch {
            await MainActor.run {
                healthStatus = "连接失败"
            }
        }
    }
}

#Preview {
    SettingsView()
}
