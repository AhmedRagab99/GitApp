import SwiftUI

/// A view to display a single line within a diff (patch).
struct DiffLineView: View {
    let line: Line // Using the Line struct from Chunk.swift
    let file: PullRequestFile
    let prCommitId: String
    @Bindable var viewModel: PullRequestViewModel

    @State private var isHovering = false
    @State private var showCommentField = false
    @State private var commentText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                // Line numbers
                Text(lineNumberText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
                    .padding(.trailing, 8)

                // Change indicator
                Text(lineIndicator)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(lineColor)
                    .frame(width: 20, alignment: .center)

                // Content
                Text(lineContent)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(lineColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)

                Spacer()

                if isHovering && canCommentOnLine {
                    Button(action: {
                        showCommentField.toggle()
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                }
            }
            .padding(.vertical, 1)
            .background(backgroundColor)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isHovering = hovering
                }
            }

            if showCommentField {
                commentInputField
                    .padding(.leading, 68) // Indent to align with content
            }
        }
    }

    private var commentInputField: some View {
        VStack {
            TextEditor(text: $commentText)
                .frame(height: 80)
                .border(Color.gray.opacity(0.5), width: 1)
                .font(.body)
            HStack {
                Button("Cancel") {
                    showCommentField = false
                    commentText = ""
                }
                .keyboardShortcut(.cancelAction)

                Button("Save Comment") {
                    guard let lineNumber = line.toFileLineNumber else { return }
                    Task {
                        await viewModel.addLineComment(
                            body: commentText,
                            commitId: prCommitId, // The head commit of the PR
                            path: file.filename,
                            line: lineNumber
                        )
                        showCommentField = false
                        commentText = ""
                    }
                }
                .disabled(commentText.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.vertical, 8)
    }

    private var canCommentOnLine: Bool {
        switch line.kind {
        case .added, .unchanged:
            return true
        default:
            return false
        }
    }

    private var lineNumberText: String {
        if line.kind == .header { return "" }
        // TODO: Implement robust old/new line number display if needed.
        // For now, using toFileLineNumber if available.
        return line.toFileLineNumber.map { "\($0)" } ?? ""
    }

    private var lineIndicator: String {
        switch line.kind {
        case .added: return "+"
        case .removed: return "-"
        case .unchanged: return " "
        case .header: return "@"
        // Conflict markers can be handled specifically if they appear in PR patches
        case .conflictStart: return "<"
        case .conflictMiddle: return "="
        case .conflictEnd: return ">"
        case .conflictOurs, .conflictTheirs: return "!" // Example
        }
    }

    private var lineContent: String {
        if line.kind == .header || line.kind == .conflictStart || line.kind == .conflictMiddle || line.kind == .conflictEnd {
            return line.raw // Show full header/conflict marker line
        }
        // For content lines, remove the leading diff char (+, -,  ) as it's shown by `lineIndicator`
        if !line.raw.isEmpty {
            let firstChar = line.raw.first
            if firstChar == "+" || firstChar == "-" || firstChar == " " {
                return String(line.raw.dropFirst())
            }
        }
        return line.raw
    }

    private var lineColor: Color {
        switch line.kind {
        case .added, .conflictOurs: return .green
        case .removed, .conflictTheirs: return .red
        case .header: return .blue
        case .unchanged: return .primary
        case .conflictStart, .conflictMiddle, .conflictEnd: return .orange
        }
    }

    private var backgroundColor: Color {
        switch line.kind {
        case .added: return Color.green.opacity(0.1)
        case .removed: return Color.red.opacity(0.1)
        case .header: return Color.blue.opacity(0.1)
        default: return Color.clear
        }
    }
}

#if DEBUG
//struct DiffLineView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Sample Chunk.Line objects for preview
//        let headerLine = Chunk.Line(id: 0, raw: "@@ -1,5 +1,6 @@")
//        var addedLine = Chunk.Line(id: 1, raw: "+This is an added line.")
//        addedLine.toFileLineNumber = 10
//        var removedLine = Chunk.Line(id: 2, raw: "-This is a removed line.")
//        // removedLine.fromFileLineNumber = 11 // Hypothetical if Line struct supported it
//        var unchangedLine = Chunk.Line(id: 3, raw: " This is an unchanged line.")
//        unchangedLine.toFileLineNumber = 12
//
//        let conflictStart = Chunk.Line(id: 4, raw: "<<<<<<< HEAD")
//        var conflictOurs = Chunk.Line(id: 5, raw: " Our conflicting line")
//        conflictOurs.isInOurConflict = true
//        let conflictMiddle = Chunk.Line(id: 6, raw: "=======")
//        var conflictTheirs = Chunk.Line(id: 7, raw: " Their conflicting line")
//        conflictTheirs.isInTheirConflict = true
//        let conflictEnd = Chunk.Line(id: 8, raw: ">>>>>>> feature-branch")
//
//
//        return ScrollView {
//            VStack(alignment: .leading, spacing: 0) {
//                DiffLineView(line: headerLine)
//                DiffLineView(line: addedLine)
//                DiffLineView(line: removedLine)
//                DiffLineView(line: unchangedLine)
//                DiffLineView(line: Chunk.Line(id: 4, raw: " Another context line"))
//                DiffLineView(line: conflictStart)
//                DiffLineView(line: conflictOurs)
//                DiffLineView(line: conflictMiddle)
//                DiffLineView(line: conflictTheirs)
//                DiffLineView(line: conflictEnd)
//            }
//            .padding()
//        }
//        .previewDisplayName("Diff Lines")
//    }
//}
#endif
