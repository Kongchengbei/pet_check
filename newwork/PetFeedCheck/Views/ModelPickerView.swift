import SwiftUI

struct ModelPickerView: View {
    @Binding var selectedModel: ModelOption
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ModelOption.available) { model in
                        Button {
                            selectedModel = model
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(PetColors.primary.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Text(String(model.displayName.prefix(1)))
                                            .font(.headline.bold())
                                            .foregroundColor(PetColors.primaryDark)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(model.displayName)
                                        .font(.body.weight(.medium))
                                        .foregroundColor(PetColors.textPrimary)
                                    Text(model.description)
                                        .font(.caption)
                                        .foregroundColor(PetColors.textSecondary)
                                }

                                Spacer()

                                if selectedModel.id == model.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(PetColors.primaryDark)
                                        .font(.title3)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                } header: {
                    Text("可用模型")
                } footer: {
                    Text("模型运行在云端，审核时间取决于图片大小和网络状况。")
                }
            }
            .navigationTitle("选择模型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ModelPickerView(selectedModel: .constant(ModelOption.available[0]))
}
