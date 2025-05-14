import SwiftUI


final class AccountsStore:ObservableObject {
     @Published var accounts: [Account] = []
     @Published var selectedAccount: Account? = nil

    init() { load() }

    func add(_ account: Account, token: String) {
        accounts.append(account)
        KeychainHelper.save(service: account.keychainService(), account: account.keychainAccount(), value: token)
        save()
    }

    func update(_ account: Account, token: String?) {
        if let idx = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[idx] = account
            if let token = token {
                KeychainHelper.save(service: account.keychainService(), account: account.keychainAccount(), value: token)
            }
            save()
        }
    }

    func remove(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        KeychainHelper.delete(service: account.keychainService(), account: account.keychainAccount())
        save()
    }

    func setDefault(_ account: Account) {
        accounts = accounts.map { var a = $0; a.isDefault = (a.id == account.id); return a }
        selectedAccount = account
        save()
    }

    func token(for account: Account) -> String? {
        KeychainHelper.read(service: account.keychainService(), account: account.keychainAccount())
    }

    func save() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: "accounts")
        }
    }

    func load() {
        if let data = UserDefaults.standard.data(forKey: "accounts"),
           let loaded = try? JSONDecoder().decode([Account].self, from: data) {
            accounts = loaded
            selectedAccount = accounts.first(where: { $0.isDefault })
        }
    }
}
