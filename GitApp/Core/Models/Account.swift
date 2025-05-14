import Foundation

enum ProviderType: String, CaseIterable, Identifiable, Codable {
    case github = "GitHub"
    case githubEnterprise = "GitHub Enterprise"
    case gitlab = "GitLab"
    case bitbucket = "Bitbucket"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .github: return "logo.github"
        case .githubEnterprise: return "building.2"
        case .gitlab: return "chevron.left.slash.chevron.right"
        case .bitbucket: return "cloud"
        }
    }
}

struct Account: Identifiable, Codable, Equatable,Hashable {
    var id: UUID = UUID()
    var provider: ProviderType
    var username: String
    var protocolType: String // "HTTPS" or "SSH"
    var isDefault: Bool = false

    func keychainService() -> String { "com.gitapp.account.\(provider.rawValue)" }
    func keychainAccount() -> String { username }
}
