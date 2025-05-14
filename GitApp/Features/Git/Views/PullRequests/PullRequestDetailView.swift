import SwiftUI

struct PullRequestDetailView: View {
    let pullRequest: PullRequest
    @State private var selectedFile: PullRequestFile?
    @State private var showingComments = false

    var body: some View {
        HSplitView {
            // Files list
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Files Changed")
                        .font(.headline)
                    Spacer()
                    Text("\(pullRequest.files.count) files")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.textBackgroundColor))

                // Files list
                List(pullRequest.files, selection: $selectedFile) { file in
                    FileChangeRow(file: file)
                }
                .listStyle(.plain)
            }
            .frame(minWidth: 300, maxWidth: 400)

            // File diff view
            if let selectedFile = selectedFile {
                FileDiffContainerView(
                    viewModel: GitViewModel(),
                    fileDiff: selectedFile.diff
                )
            } else {
                ContentUnavailableView("Select a File",
                    systemImage: "doc",
                    description: Text("Choose a file to view its changes")
                )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showingComments.toggle() }) {
                    Label("Comments", systemImage: "bubble.left")
                }

                Menu {
                    Button(action: { /* TODO: Approve PR */ }) {
                        Label("Approve", systemImage: "checkmark.circle")
                    }
                    Button(action: { /* TODO: Request changes */ }) {
                        Label("Request Changes", systemImage: "exclamationmark.circle")
                    }
                    Button(action: { /* TODO: Comment */ }) {
                        Label("Comment", systemImage: "bubble.left")
                    }
                } label: {
                    Label("Review", systemImage: "checklist")
                }
            }
        }
        .sheet(isPresented: $showingComments) {
            CommentsView(comments: pullRequest.comments)
        }
    }
}

struct FileChangeRow: View {
    let file: PullRequestFile

    var body: some View {
        HStack {
            Image(systemName: file.status.icon)
                .foregroundColor(Color(file.status.color))

            VStack(alignment: .leading, spacing: 4) {
                Text(file.path)
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    if file.additions > 0 {
                        Label("+\(file.additions)", systemImage: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                    if file.deletions > 0 {
                        Label("-\(file.deletions)", systemImage: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .font(.caption)
            }

            Spacer()

            Text(file.status.rawValue.capitalized)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(file.status.color).opacity(0.2))
                .foregroundColor(Color(file.status.color))
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
}

struct CommentsView: View {
    let comments: [PullRequestComment]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(comments) { comment in
                CommentRow(comment: comment)
            }
            .navigationTitle("Comments")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CommentRow: View {
    let comment: PullRequestComment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.author)
                    .font(.headline)
                Spacer()
                Text(comment.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(comment.content)
                .font(.body)

            if let path = comment.path {
                HStack {
                    Image(systemName: "doc")
                    Text(path)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
