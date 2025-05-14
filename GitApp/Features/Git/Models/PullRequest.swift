import Foundation

struct PullRequest: Identifiable, Hashable {
    let id: String
    let number: Int
    let title: String
    let description: String
    let author: String
    let state: PullRequestState
    let createdAt: Date
    let updatedAt: Date
    let baseBranch: String
    let headBranch: String
    var files: [PullRequestFile]
    let comments: [PullRequestComment]
    let reviewStatus: ReviewStatus

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PullRequest, rhs: PullRequest) -> Bool {
        lhs.id == rhs.id
    }
}

enum PullRequestState: String {
    case open = "open"
    case closed = "closed"
    case merged = "merged"

    var color: String {
        switch self {
        case .open: return "green"
        case .closed: return "red"
        case .merged: return "purple"
        }
    }

    var icon: String {
        switch self {
        case .open: return "arrow.triangle.pull"
        case .closed: return "xmark.circle"
        case .merged: return "arrow.triangle.merge"
        }
    }
}

struct PullRequestFile: Identifiable,Hashable {
    let id = UUID()
    let path: String
    let status: FileStatus
    let additions: Int
    let deletions: Int
    let changes: Int
    let diff: FileDiff
}

enum GitHubFileStatus: String {
    case added = "added"
    case modified = "modified"
    case removed = "removed"
    case renamed = "renamed"

    var icon: String {
        switch self {
        case .added: return "plus.circle"
        case .modified: return "pencil"
        case .removed: return "minus.circle"
        case .renamed: return "arrow.right.circle"
        }
    }

    var color: String {
        switch self {
        case .added: return "green"
        case .modified: return "blue"
        case .removed: return "red"
        case .renamed: return "orange"
        }
    }
}

struct PullRequestComment: Identifiable {
    let id: String
    let author: String
    let content: String
    let createdAt: Date
    let path: String?
    let line: Int?
}

enum ReviewStatus: String {
    case approved = "approved"
    case changesRequested = "changes_requested"
    case pending = "pending"

    var icon: String {
        switch self {
        case .approved: return "checkmark.circle.fill"
        case .changesRequested: return "exclamationmark.circle.fill"
        case .pending: return "clock.fill"
        }
    }

    var color: String {
        switch self {
        case .approved: return "green"
        case .changesRequested: return "red"
        case .pending: return "orange"
        }
    }
}
