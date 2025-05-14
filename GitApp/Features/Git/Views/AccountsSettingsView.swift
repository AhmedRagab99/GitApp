//
//  AccountsSettingsView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 15/05/2025.
//


import SwiftUI

struct AccountsSettingsView: View {
    @EnvironmentObject var store : AccountsStore
    @State private var showEditSheet = false
    @State private var editingAccount: Account?
    @State private var editingToken: String?

    var body: some View {
        VStack {
            List(selection: $store.selectedAccount) {
                ForEach(store.accounts) { account in
                    HStack {
                        Image(systemName: account.provider.icon)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text(account.username)
                                .font(.headline)
                            Text(account.provider.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if account.isDefault {
                            Label("Default", systemImage: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        store.selectedAccount = account
                    }
                }
            }
            .listStyle(.inset)
            .frame(minHeight: 200)

            HStack {
                Button("Add...") {
                    editingAccount = nil
                    editingToken = nil
                    showEditSheet = true
                }
                Button("Edit...") {
                    if let selected = store.selectedAccount {
                        editingAccount = selected
                        editingToken = store.token(for: selected)
                        showEditSheet = true
                    }
                }
                .disabled(store.selectedAccount == nil)
                Button("Remove...") {
                    if let selected = store.selectedAccount {
                        store.remove(selected)
                    }
                }
                .disabled(store.selectedAccount == nil)
                Spacer()
                Button("Set Default...") {
                    if let selected = store.selectedAccount {
                        store.setDefault(selected)
                    }
                }
                .disabled(store.selectedAccount == nil)
            }
            .padding()
        }
        .sheet(isPresented: $showEditSheet) {
            AccountEditView(account: editingAccount, token: editingToken, onSave: { account, token in
                if let editing = editingAccount {
                    store.update(account, token: token)
                } else {
                    store.add(account, token: token)
                }
                showEditSheet = false
            }, onCancel: {
                showEditSheet = false
            })
        }
        .navigationTitle("Accounts")
    }
}
