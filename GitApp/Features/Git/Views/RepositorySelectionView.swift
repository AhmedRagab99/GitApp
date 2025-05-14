//
//  RepositorySelectionView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//
import SwiftUI
import AppKit


struct RepositorySelectionView: View {
    var viewModel: RepositoryViewModel
    @EnvironmentObject var accountStore: AccountsStore
    @State private var selectedRepository: URL?
    @State private var isShowingFilePicker = false
    @State private var isShowingCloneSheet = false
    @State private var isShowingErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Modern header section
            VStack(spacing: 16) {
                Text("Git Client")
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack(spacing: 12) {
                    Button {
                        isShowingFilePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                            Text("Open")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        isShowingCloneSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                            Text("Clone")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
            }
            .padding()
            .background(Color(.windowBackgroundColor))

            // Repository List
            List(selection: $selectedRepository) {
                if viewModel.recentRepositories.isEmpty {
                    ContentUnavailableView {
                        Label("No Recent Repositories", systemImage: "folder.badge.questionmark")
                    } description: {
                        Text("Open a local repository or clone from remote to get started")
                    }
                } else {
                    Text("Recent Repositories")
                        .font(.headline)
                        .padding(.vertical, 4)
                    ForEach(viewModel.recentRepositories, id: \.self) { url in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(url.lastPathComponent)
                                .font(.headline)
                            Text(url.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(url == selectedRepository ? Color.accentColor.opacity(0.15) : Color.clear)
                        )

                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.removeFromRecentRepositories(url)
                                if url == selectedRepository {
                                    selectedRepository = nil
                                }
                            } label: {
                                Label("Remove from Recent", systemImage: "trash")
                            }

                            Button(role: .destructive) {
                                handleWindow(with: url)
                            } label: {
                                Label("Open Repo", systemImage: "folder")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.removeFromRecentRepositories(url)
                                if url == selectedRepository {
                                    selectedRepository = nil
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
//            .listStyle(.insetGrouped)
        }
//        .loading(viewModel.isLoading)
        .errorAlert(viewModel.errorMessage)
        .sheet(isPresented: $isShowingCloneSheet) {
            CloneRepositoryView(viewModel: viewModel)
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedRepository = url
                    viewModel.addImportedRepository(url)

                }

            case .failure(let error):
                errorMessage = error.localizedDescription
                isShowingErrorAlert = true
            }
        }
        .alert("Error", isPresented: $isShowingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await viewModel.loadRepositoryList()
            }
        }

    }

    private func handleWindow(with url: URL){
        let windowId = url.lastPathComponent
        if  isWindowVisible(id: windowId) {
            bringWindowToFront(id: windowId)
        } else {
            let viewModel = GitViewModel()
//            let account = accountStore.accounts.first(where: { $0.isDefault && $0.provider == .github })!
            
//             viewModel.updateAuthToken(accountStore.token(for: account) ?? "")
            let view = GitClientView(viewModel:viewModel, url: url)
//            func updateAuthToken(_ token: String) {
//                Task { @MainActor in
//                    await githubService.updateToken(token)
//                }
//            }
            openNewWindow(with: view, id: windowId, title: windowId, width: (NSScreen.main?.frame.width ?? 600) / 2, height: (NSScreen.main?.frame.height ?? 600) / 2)
        }
    }
}

#Preview {
    RepositorySelectionView(viewModel: RepositoryViewModel())
}
