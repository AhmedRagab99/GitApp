import SwiftUI

struct AccountEditView: View {
    @State var account: Account
    @State var token: String
    var onSave: (Account, String) -> Void
    var onCancel: () -> Void

    init(account: Account?, token: String?, onSave: @escaping (Account, String) -> Void, onCancel: @escaping () -> Void) {
        _account = State(initialValue: account ?? Account(provider: .github, username: "", protocolType: "HTTPS"))
        _token = State(initialValue: token ?? "")
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        Form {
            Picker("Provider", selection: $account.provider) {
                ForEach(ProviderType.allCases) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            TextField("Username", text: $account.username)
            SecureField("Access Token", text: $token)
            Picker("Protocol", selection: $account.protocolType) {
                Text("HTTPS").tag("HTTPS")
                Text("SSH").tag("SSH")
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: onCancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    onSave(account, token)
                }
                .disabled(account.username.isEmpty || token.isEmpty)
            }
        }
    }
}
