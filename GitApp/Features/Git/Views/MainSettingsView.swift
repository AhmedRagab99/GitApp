import SwiftUI

struct MainSettingsView: View {
    var body: some View {
        TabView {
            AccountsSettingsView()
                .tabItem {
                    Label("Accounts", systemImage: "person.crop.circle")
                }
            // Add other settings tabs here
        }
        .frame(minWidth: 500, minHeight: 350)
    }
}
