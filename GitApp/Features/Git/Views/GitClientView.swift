import SwiftUI

// Import all models
import Foundation
import AppKit

struct GitClientView: View {
    @Bindable var viewModel: GitViewModel
    var url: URL
    @State private var selectedWorkspaceItem: WorkspaceSidebarItem = .history
    @State private var showStashSheet = false
    @State private var showDeleteAlert = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showCreateBranchSheet = false
    @State private var newBranchName = ""
    @State private var stashMessage = ""
    @State private var keepStaged = false
    @State private var showPushSheet = false
    @State private var showPullSheet = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel, selectedWorkspaceItem: $selectedWorkspaceItem)
        } detail: {
            VStack(spacing: 0) {
                // Main content area
                if selectedWorkspaceItem == .workingCopy {
                    CommitView(viewModel: viewModel)
                } else if selectedWorkspaceItem == .history {
                    HistoryView(viewModel: viewModel)
                } else if selectedWorkspaceItem == .pullRequests {
                    PullRequestListView(viewModel: viewModel)
                }
                else {
                    // Optionally, add a search view or placeholder
                    Text("Search coming soon...")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .loading(viewModel.isLoading)
        .errorAlert(viewModel.errorMessage)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Primary Actions Group
                Group {
                    Button(action: {
                            showPullSheet = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 20))
                            Text("Pull")
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .overlay(alignment: .topTrailing) {
                            if viewModel.syncState.shouldPull {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        showPushSheet = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 20))
                            Text("Push")
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .overlay(alignment: .topTrailing) {
                            if  viewModel.pendingPushCount > 0 {
                                let count = viewModel.pendingPushCount
                                Text("\(count)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(.blue))
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        // Show commit sheet
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Commit")
                                .font(.caption)
                        }
                        .frame(width: 60)
                        .overlay(alignment: .topTrailing) {
                            if viewModel.pendingCommitsCount > 0 {
                                Text("\(viewModel.pendingCommitsCount)")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(.blue))
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        showCreateBranchSheet = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.square.on.square")
                                .font(.system(size: 20))
                            Text("New Branch")
                                .font(.caption)
                        }
                        .frame(width: 80)
                    }
                    .buttonStyle(.plain)

                    Button(action: { showStashSheet = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: "archivebox")
                                .font(.system(size: 20))
                            Text("Stash")
                                .font(.caption)
                        }
                        .frame(width: 60)
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .padding(.horizontal, 8)

                // Secondary Actions Group
                Group {
                    Button(action: {
                        // Show merge sheet
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.merge")
                                .font(.system(size: 20))
                            Text("Merge")
                                .font(.caption)
                        }
                        .frame(width: 60)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 20))
                            Text("Delete")
                                .font(.caption)
                        }
                        .frame(width: 60)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showPushSheet) {
            PushSheet(
                isPresented: $showPushSheet,
                branches: viewModel.branches,
                currentBranch: viewModel.currentBranch,
                onPush: { selectedBranches, pushTags in
                    Task {
                        for branch in selectedBranches {
                            await viewModel.push(branch: branch, pushTags: pushTags)
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showStashSheet) {
            CreateStashSheet(
                isPresented: $showStashSheet,
                onStash: { message, keepStaged in
                    Task {
                        await viewModel.createStash(message: message, keepStaged: keepStaged)
                    }
                }
            )
        }
        .sheet(isPresented: $showPullSheet) {
            PullSheet(
                isPresented: $showPullSheet,
                remotes: ["origin"],
                remoteBranches: viewModel.remotebranches.map { $0.name },
                localBranches: viewModel.branches.map { $0.name },
                currentRemote: "origin",
                currentRemoteBranch: viewModel.currentBranch?.name ?? "",
                currentLocalBranch: viewModel.currentBranch?.name ?? "",
                onPull: { remote, remoteBranch, localBranch, options in
                    Task {
                        await viewModel.pull(remote: remote, remoteBranch: remoteBranch, localBranch: localBranch, options: options)
                    }
                }
            )
        }
        .sheet(isPresented: $showCreateBranchSheet) {
            CreateBranchSheet(
                isPresented: $showCreateBranchSheet,
                currentBranch: viewModel.currentBranch?.name ?? "",
                onCreate: { branchName, commitSource, specifiedCommit, checkout in
                    Task {
                        await viewModel.createBranch(named: branchName, checkout: checkout)
                    }
                }
            )
        }
        .onAppear {
            viewModel.selectRepository(url)

        }
        .alert("Delete Branch", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
//                if let branch = viewModel.currentBranch {
//                    Task {
//                        await viewModel.deleteBranch(branch)
//                    }
//                }
            }
        } message: {
            Text("Are you sure you want to delete this branch?")
        }
    }
}


// Syntax Highlighting Colors
enum SyntaxTheme {
    static let added = Color.green.opacity(0.1)
    static let removed = Color.red.opacity(0.1)
    static let lineNumber = Color.gray.opacity(0.5)
    static let addedText = Color.green
    static let removedText = Color.red
    static let normalText = Color.clear
}

// Modern UI Constants
enum ModernUI {
    static let spacing: CGFloat = 8
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 8
    static let animation: Animation = .spring(response: 0.3, dampingFraction: 0.7)

    enum colors {
        static let background = Color(.windowBackgroundColor)
        static let secondaryBackground = Color(.controlBackgroundColor)
        static let selection = Color(.selectedContentBackgroundColor)
        static let border = Color(.separatorColor)
        static let secondaryText = Color(.secondaryLabelColor)
    }

    enum shadow {
        case small, medium, large

        var radius: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 8
            }
        }
        var colors: Color {
            switch self {
                case .small: return Color.black.opacity(0.1)
                case .medium: return Color.black.opacity(0.2)
            case .large: return Color.black.opacity(0.3)
            }
        }


        var offset: CGFloat {
            switch self {
            case .small: return 1
            case .medium: return 2
            case .large: return 4
            }
        }
    }
}
//
//extension View {
//    func modernShadow(_ style: ModernUI.shadow) -> some View {
//        self.shadow(
//            color: .black.opacity(0.1),
//            radius: style.radius,
//            x: 0,
//            y: style.offset
//        )
//    }
//}




