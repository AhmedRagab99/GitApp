//
//  GitAppApp.swift
//  GitApp
//
//  Created by Ahmed Ragab on 17/04/2025.
//

import SwiftUI

@main
struct GitAppApp: App {
    @StateObject private var store = AccountsStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        Settings {
            MainSettingsView()
                .environmentObject(store)
        }
    }
}
