import Foundation

actor GitHubService {
    private let baseURL = "https://api.github.com"
    private var authToken: String? = 
    private var rateLimitRemaining: Int = 5000
    private var rateLimitReset: Date?

   func updateToken(_ token: String) async {
        authToken = token
    }

    // MARK: - Error Handling
    private func handleResponse(_ response: HTTPURLResponse, data: Data) throws {
        // Check rate limiting
        if let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
           let remainingInt = Int(remaining) {
            rateLimitRemaining = remainingInt
        }

        if let reset = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
           let resetTime = Double(reset) {
            rateLimitReset = Date(timeIntervalSince1970: resetTime)
        }

        // Handle different status codes
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw GitHubError.unauthorized
        case 403:
            if rateLimitRemaining == 0 {
                throw GitHubError.rateLimitExceeded(resetTime: rateLimitReset)
            }
            throw GitHubError.forbidden
        case 404:
            throw GitHubError.notFound
        case 422:
            throw GitHubError.validationFailed
        default:
            throw GitHubError.serverError(statusCode: response.statusCode)
        }
    }

    // MARK: - Pull Request Operations
    func createPullRequest(owner: String, repo: String, title: String, body: String, head: String, base: String) async throws -> PullRequest {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/pulls")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload = CreatePullRequestPayload(
            title: title,
            body: body,
            head: head,
            base: base
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }

        try handleResponse(httpResponse, data: data)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let pr = try decoder.decode(GitHubPullRequest.self, from: data)
        return pr.toPullRequest()
    }

    func fetchPullRequests(for repository: String, owner: String) async throws -> [PullRequest] {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repository)/pulls")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GitHubError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let prs = try decoder.decode([GitHubPullRequest].self, from: data)
        return prs.map { $0.toPullRequest() }
    }

    func fetchPullRequestDetails(owner: String, repo: String, number: Int) async throws -> PullRequest {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/pulls/\(number)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GitHubError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let pr = try decoder.decode(GitHubPullRequest.self, from: data)
        return pr.toPullRequest()
    }

    func fetchPullRequestFiles(owner: String, repo: String, number: Int) async throws -> [PullRequestFile] {
        let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/pulls/\(number)/files")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GitHubError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let files = try decoder.decode([GitHubPullRequestFile].self, from: data)
        return files.map { $0.toPullRequestFile() }
    }
}

// MARK: - GitHub API Models
private struct GitHubPullRequest: Codable {
    let id: Int
    let number: Int
    let title: String
    let body: String?
    let user: GitHubUser
    let state: String
    let createdAt: Date
    let updatedAt: Date
    let base: GitHubBranch
    let head: GitHubBranch
    let reviewComments: Int
    let comments: Int

    func toPullRequest() -> PullRequest {
        PullRequest(
            id: String(id),
            number: number,
            title: title,
            description: body ?? "",
            author: user.login,
            state: PullRequestState(rawValue: state) ?? .open,
            createdAt: createdAt,
            updatedAt: updatedAt,
            baseBranch: base.ref,
            headBranch: head.ref,
            files: [], // Files will be fetched separately
            comments: [], // Comments will be fetched separately
            reviewStatus: .pending // Default status
        )
    }
}

private struct GitHubUser: Codable {
    let login: String
}

private struct GitHubBranch: Codable {
    let ref: String
}

private struct GitHubPullRequestFile: Codable {
    let sha: String
    let filename: String
    let status: String
    let additions: Int
    let deletions: Int
    let changes: Int
    let patch: String?

    func toPullRequestFile() -> PullRequestFile {
        let status: FileStatus
        switch self.status {
        case "added": status = .added
        case "modified": status = .modified
        case "removed": status = .removed
        case "renamed": status = .renamed
        default: status = .modified
        }

        // Create a FileDiff from the patch
        let diff = try! FileDiff(
            raw: patch ?? ""
        )

        return PullRequestFile(
            path: filename,
            status: status,
            additions: additions,
            deletions: deletions,
            changes: changes,
            diff: diff
        )
    }

    private func parsePatch(_ patch: String) -> [Chunk] {
        // Basic patch parsing - you might want to enhance this
        let lines = patch.components(separatedBy: .newlines)
        var chunks: [Chunk] = []
        var currentChunk: Chunk?
        var oldLines: [String] = []
        var newLines: [String] = []

//        for line in lines {
//            if line.hasPrefix("@@") {
//                if let chunk = currentChunk {
//                    chunks.append(chunk)
//                }
//                currentChunk = Chunk()
//            } else if let chunk = currentChunk {
//                if line.hasPrefix("-") {
//                    chunk.oldLines.append(line)
//                } else if line.hasPrefix("+") {
//                    chunk.newLines.append(line)
//                } else {
//                    chunk.oldLines.append(line)
//                    chunk.newLines.append(line)
//                }
//            }
//        }

        if let chunk = currentChunk {
            chunks.append(chunk)
        }

        return chunks
    }
}

// MARK: - Additional Models
private struct CreatePullRequestPayload: Codable {
    let title: String
    let body: String
    let head: String
    let base: String
}

// MARK: - Enhanced Error Types
enum GitHubError: LocalizedError {
    case invalidResponse
    case decodingError
    case networkError
    case unauthorized
    case forbidden
    case notFound
    case validationFailed
    case serverError(statusCode: Int)
    case rateLimitExceeded(resetTime: Date?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from GitHub API"
        case .decodingError:
            return "Failed to decode GitHub API response"
        case .networkError:
            return "Network error occurred"
        case .unauthorized:
            return "Unauthorized: Please check your authentication token"
        case .forbidden:
            return "Forbidden: You don't have permission to access this resource"
        case .notFound:
            return "Resource not found"
        case .validationFailed:
            return "Validation failed: Please check your input"
        case .serverError(let statusCode):
            return "Server error occurred (Status code: \(statusCode))"
        case .rateLimitExceeded(let resetTime):
            if let resetTime = resetTime {
                return "Rate limit exceeded. Reset at \(resetTime.formatted())"
            }
            return "Rate limit exceeded"
        }
    }
}
