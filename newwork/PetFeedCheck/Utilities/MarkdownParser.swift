import Foundation

struct MarkdownParser {

    static func parse(_ markdown: String) -> [MarkdownNode] {
        guard !markdown.isEmpty else {
            return [MarkdownNode(type: .paragraph, content: "暂无内容")]
        }

        let lines = markdown.components(separatedBy: "\n")
        var result: [MarkdownNode] = []
        var inCodeBlock = false
        var codeBlockContent: [String] = []
        var codeBlockLang = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Code block fences
            if trimmed.hasPrefix("```") {
                if !inCodeBlock {
                    inCodeBlock = true
                    codeBlockLang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    codeBlockContent = []
                } else {
                    inCodeBlock = false
                    result.append(MarkdownNode(type: .codeBlock, content: codeBlockContent.joined(separator: "\n"), language: codeBlockLang))
                    codeBlockContent = []
                    codeBlockLang = ""
                }
                continue
            }

            if inCodeBlock {
                codeBlockContent.append(line)
                continue
            }

            guard !trimmed.isEmpty else { continue }

            // Horizontal rule
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                result.append(MarkdownNode(type: .horizontalRule, content: ""))
                continue
            }

            // Headers
            if trimmed.hasPrefix("#### ") {
                result.append(MarkdownNode(type: .h4, content: cleanText(String(trimmed.dropFirst(5)))))
                continue
            }
            if trimmed.hasPrefix("### ") {
                result.append(MarkdownNode(type: .h3, content: cleanText(String(trimmed.dropFirst(4)))))
                continue
            }
            if trimmed.hasPrefix("## ") {
                result.append(MarkdownNode(type: .h2, content: cleanText(String(trimmed.dropFirst(3)))))
                continue
            }
            if trimmed.hasPrefix("# ") {
                result.append(MarkdownNode(type: .h1, content: cleanText(String(trimmed.dropFirst(2)))))
                continue
            }

            // Unordered list
            if trimmed.hasPrefix("- ") {
                result.append(MarkdownNode(type: .listItem, content: cleanText(String(trimmed.dropFirst(2)))))
                continue
            }
            if trimmed.hasPrefix("* ") {
                result.append(MarkdownNode(type: .listItem, content: cleanText(String(trimmed.dropFirst(2)))))
                continue
            }

            // Ordered list
            if let match = trimmed.firstMatch(of: /^(\d+)\.\s+(.*)$/) {
                let order = String(match.output.1)
                let text = cleanText(String(match.output.2))
                result.append(MarkdownNode(type: .orderedItem, content: text, order: order))
                continue
            }

            // Blockquote
            if trimmed.hasPrefix("> ") {
                result.append(MarkdownNode(type: .blockquote, content: cleanText(String(trimmed.dropFirst(2)))))
                continue
            }

            // Status indicators
            if trimmed.hasPrefix("✅") || trimmed.hasPrefix("✓") {
                result.append(MarkdownNode(type: .success, content: cleanText(String(trimmed.dropFirst(1)))))
                continue
            }
            if trimmed.hasPrefix("❌") || trimmed.hasPrefix("✗") {
                result.append(MarkdownNode(type: .error, content: cleanText(String(trimmed.dropFirst(1)))))
                continue
            }
            if trimmed.hasPrefix("⚠️") || trimmed.hasPrefix("⚠") {
                result.append(MarkdownNode(type: .warning, content: cleanText(String(trimmed.dropFirst(1)))))
                continue
            }

            // Bold paragraph vs plain
            if trimmed.contains("**") || trimmed.contains("__") {
                result.append(MarkdownNode(type: .boldParagraph, content: cleanText(trimmed)))
            } else {
                result.append(MarkdownNode(type: .paragraph, content: cleanText(trimmed)))
            }
        }

        // Unclosed code block
        if inCodeBlock && !codeBlockContent.isEmpty {
            result.append(MarkdownNode(type: .codeBlock, content: codeBlockContent.joined(separator: "\n"), language: codeBlockLang))
        }

        return result.isEmpty ? [MarkdownNode(type: .paragraph, content: "暂无内容")] : result
    }

    private static func cleanText(_ text: String) -> String {
        var t = text
        // Remove **bold** markers
        t = t.replacingOccurrences(of: "**", with: "")
        t = t.replacingOccurrences(of: "__", with: "")
        // Remove *italic* markers
        t = t.replacingOccurrences(of: "*", with: "")
        t = t.replacingOccurrences(of: "_", with: "")
        // Remove `code` backticks
        t = t.replacingOccurrences(of: "`", with: "")
        // Remove markdown links, keep text: [text](url) -> text
        while let range = t.firstMatch(of: /\[([^\]]+)\]\([^)]+\)/) {
            t.replaceSubrange(t.range(of: t[range.range])!, with: String(range.output.1))
        }
        return t
    }
}
