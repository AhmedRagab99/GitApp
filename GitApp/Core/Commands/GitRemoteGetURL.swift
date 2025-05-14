import Foundation

struct GitRemoteGetURL: Git {
    typealias OutputModel = String

    let directory: URL

    var arguments: [String] {
        ["git", "remote", "get-url", "origin"]
    }

    func parse(for output: String) throws -> String {
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
