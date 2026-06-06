import SwiftUI

struct AuditResultView: View {
    let nodes: [MarkdownNode]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(nodes) { node in
                markdownNodeView(for: node)
            }
        }
    }

    @ViewBuilder
    private func markdownNodeView(for node: MarkdownNode) -> some View {
        switch node.type {
        case .h1:
            Text(node.content)
                .font(.title.bold())
                .foregroundColor(PetColors.textPrimary)
                .padding(.bottom, 2)

        case .h2:
            Text(node.content)
                .font(.title2.bold())
                .foregroundColor(PetColors.textPrimary)
                .padding(.top, 8)
                .padding(.bottom, 2)

        case .h3:
            Text(node.content)
                .font(.title3.bold())
                .foregroundColor(PetColors.primaryDark)
                .padding(.top, 4)

        case .h4:
            Text(node.content)
                .font(.headline)
                .foregroundColor(PetColors.textSecondary)

        case .horizontalRule:
            Divider()
                .padding(.vertical, 4)

        case .listItem:
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(PetColors.primary)
                    .frame(width: 6, height: 6)
                    .padding(.top, 7)
                Text(node.content)
                    .font(.subheadline)
                    .foregroundColor(PetColors.textPrimary)
            }
            .padding(.leading, 4)

        case .orderedItem:
            HStack(alignment: .top, spacing: 8) {
                Text("\(node.order ?? "?").")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(PetColors.primaryDark)
                    .frame(minWidth: 24, alignment: .trailing)
                Text(node.content)
                    .font(.subheadline)
                    .foregroundColor(PetColors.textPrimary)
            }
            .padding(.leading, 4)

        case .blockquote:
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(PetColors.primaryLight)
                    .frame(width: 4)
                Text(node.content)
                    .font(.subheadline.italic())
                    .foregroundColor(PetColors.textSecondary)
                    .padding(.leading, 10)
            }
            .padding(.vertical, 4)

        case .codeBlock:
            VStack(alignment: .leading, spacing: 0) {
                if let lang = node.language, !lang.isEmpty {
                    Text(lang)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(PetColors.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                Text(node.content)
                    .font(.caption.monospaced())
                    .foregroundColor(PetColors.textPrimary)
                    .padding(12)
            }
            .background(PetColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.vertical, 4)

        case .success:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(PetColors.success)
                    .font(.subheadline)
                Text(node.content)
                    .font(.subheadline)
                    .foregroundColor(PetColors.textPrimary)
            }
            .padding(10)
            .background(PetColors.success.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        case .error:
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(PetColors.error)
                    .font(.subheadline)
                Text(node.content)
                    .font(.subheadline)
                    .foregroundColor(PetColors.textPrimary)
            }
            .padding(10)
            .background(PetColors.error.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        case .warning:
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(PetColors.warning)
                    .font(.subheadline)
                Text(node.content)
                    .font(.subheadline)
                    .foregroundColor(PetColors.textPrimary)
            }
            .padding(10)
            .background(PetColors.warning.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        case .info:
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(PetColors.info)
                    .font(.subheadline)
                Text(node.content)
                    .font(.subheadline)
                    .foregroundColor(PetColors.textPrimary)
            }
            .padding(10)
            .background(PetColors.info.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

        case .paragraph:
            Text(node.content)
                .font(.subheadline)
                .foregroundColor(PetColors.textPrimary)

        case .boldParagraph:
            Text(node.content)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(PetColors.textPrimary)
        }
    }
}

#Preview {
    ScrollView {
        AuditResultView(nodes: [
            MarkdownNode(type: .h1, content: "宠粮审核报告"),
            MarkdownNode(type: .h2, content: "基本信息"),
            MarkdownNode(type: .listItem, content: "审核时间: 2026-06-06"),
            MarkdownNode(type: .success, content: "合规判定: 合规"),
            MarkdownNode(type: .warning, content: "请注意查看配料表"),
        ])
    }
    .padding()
}
