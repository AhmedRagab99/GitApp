//
//  SidebarView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 18/04/2025.
//

import SwiftUI
import Foundation


enum SidebarItem: Identifiable, Equatable,Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool { lhs.id == rhs.id }
    case workspace(WorkspaceSidebarItem)
    case branch(BranchNode)
    case remote(BranchNode)
    case tag(Tag)
    case section(String)
    case stash(Stash)
    var id: String {
        switch self {
        case .workspace(let w): return "workspace-\(w.id)"
        case .branch(let b): return "branch-\(b.id)"
        case .remote(let r): return "remote-\(r.id)"
        case .tag(let t): return "tag-\(t.id)"
        case .section(let s): return "section-\(s)"
        case .stash(let s): return "stash-\(s.id)"
        }
    }
    var children: [SidebarItem]? {
        switch self {
        case .branch(let node): return node.children?.map { .branch($0) }
        case .remote(let node): return node.children?.map { .remote($0) }
        default: return nil
        }
    }
    var isExpandable: Bool { children != nil }
}

struct BranchNode: Identifiable {
    let id = UUID() // Unique ID for the list item
    let name: String // Name of the folder or branch segment
    var children: [BranchNode]? // Child nodes (folders or branches within this folder) - Use optional for leaf nodes
    var branch: Branch? = nil // The actual branch data, only set for leaf nodes

    // Convenience initializer for folder nodes
    init(name: String, children: [BranchNode] = []) {
        self.name = name
        // Only set children if the array is not empty, otherwise use nil for List's children detection
        self.children = children.isEmpty ? nil : children
        self.branch = nil
    }

    // Convenience initializer for leaf nodes (representing branches)
    init(branch: Branch) {
        // Leaf node name is derived from the last path component if '/' is present, otherwise full name
        self.name = branch.name.components(separatedBy: "/").last ?? branch.name
        self.children = nil // Leaf nodes have no children
        self.branch = branch
    }

    // Helper to determine if this node represents a folder (has children or is intended as a container)
    var isFolder: Bool {
        // A node is considered a folder if it explicitly has children
        // or if it doesn't represent a final branch leaf.
        return children != nil
    }
}

// Workspace items for the top section
enum WorkspaceSidebarItem: String, CaseIterable, Identifiable {
    case workingCopy = "Working Copy"
    case history = "History"
    case stashes = "Stashes"
    case pullRequests = "Pull Requests"
    case branchesReview = "Branches Review"
    case settings = "Settings"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .workingCopy: return "folder"
        case .history: return "clock"
        case .stashes: return "archivebox"
        case .pullRequests: return "arrow.triangle.branch"
        case .branchesReview: return "point.topleft.down.curvedto.point.bottomright.up"
        case .settings: return "gearshape"
        }
    }
}

struct SidebarView: View {
    @Bindable var viewModel: GitViewModel
    @Binding var selectedWorkspaceItem: WorkspaceSidebarItem
    @State private var filterText: String = ""
    @State private var selectedSidebarItem: SidebarItem? = .workspace(.history)
    @State private var sidebarItems: [SidebarItem] = []
    @State private var showingPullRequests = false

    var body: some View {
        SwiftUISidebarView(
            items: sidebarItems,
            selectedItem: $selectedSidebarItem,
            selectedWorkspaceItem: $selectedWorkspaceItem,
            onBranchAction: handleBranchAction,
            onRemoteAction: handleRemoteAction,
            onTagAction: handleTagAction,
            onStashAction: handleStashAction,
            refresh: refreshSidebar
        )
        .frame(minWidth: 240)

        .onChange(of: viewModel.branches) {
            refreshSidebar()
        }
        .onChange(of: viewModel.tags) {
            refreshSidebar()
        }
        .onChange(of: viewModel.remotebranches) {
            refreshSidebar()
        }
        .onChange(of: viewModel.stashes) {
            refreshSidebar()
        }
//        .onChange(of: selectedSidebarItem) { newValue in
//            if case let .workspace(item) = newValue {
//                selectedWorkspaceItem = item
//                if item == .pullRequests {
//                    showingPullRequests = true
//                }
//            }
//        }
    }

    private func handleBranchAction(_ action: BranchContextAction, _ branch: Branch) {
            switch action {
            case .checkout:
                Task { await viewModel.checkoutBranch(branch) }
            case .pull:
                Task { await viewModel.performPull() }
            case .push:
                Task { await viewModel.performPush() }
            case .copyName:
                viewModel.copyCommitHash(branch.name)
            // ... handle other actions ...
            default: break
            }
            refreshSidebar()
        }

        private func handleRemoteAction(_ action: RemoteContextAction, _ branch: Branch) {
            switch action {
            case .checkout:
                Task { await viewModel.checkoutBranch(branch, isRemote: true) }
            case .copyName:
                viewModel.copyCommitHash(branch.name)
            // ... handle other actions ...
            default: break
            }
            refreshSidebar()
        }

        private func handleTagAction(_ action: TagContextAction, _ tag: Tag) {
            switch action {
            case .copyName:
                viewModel.copyCommitHash(tag.name)
            // ... handle other actions ...
            default: break
            }
            refreshSidebar()
        }

    private func handleStashAction(_ action: StashContextAction, _ tag: Stash)  {
        switch action {
        case .apply:
            Task {
               await viewModel.applyStash(at: tag.index)
            }
        case .delete:
            Task {
               await viewModel.deleteStash(at: tag.index)
            }
        }
        refreshSidebar()
    }

    private func refreshSidebar() {
        var items: [SidebarItem] = []
        // Workspace section
        items.append(.section("Workspace"))
        items.append(contentsOf: WorkspaceSidebarItem.allCases.map { .workspace($0) })
        // Branches section
        items.append(.section("Branches"))
        let branchTree = buildBranchTreeRevised(from: viewModel.branches)
        items.append(contentsOf: branchTree.map { .branch($0) })
        // Remotes section
        items.append(.section("Remotes"))
        let remoteTree = buildBranchTreeRevised(from: viewModel.remotebranches)
        items.append(contentsOf: remoteTree.map { .remote($0) })
        // Stashes Section
        items.append(.section("Stashes"))
        items.append(contentsOf: viewModel.stashes.map { .stash($0) })
        // Tags section
        items.append(.section("Tags"))
        items.append(contentsOf: viewModel.tags.map { .tag($0) })


        sidebarItems = items
    }

    // Use your existing buildBranchTreeRevised logic
    func buildBranchTreeRevised(from branches: [Branch]) -> [BranchNode] {
        // Temporary storage: Key = full folder path, Value = (Set<ChildFolderName>, [DirectChildBranches])
        var structure: [String: (subfolders: Set<String>, branches: [Branch])] = [:]
        var rootFolders = Set<String>()
        var rootBranches: [Branch] = []

        // Sort branches for consistent tree order
        let sortedBranches = branches.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }

        for branch in sortedBranches {
            let components = branch.name.components(separatedBy: "/")
            if components.count == 1 {
                // Root level branch
                rootBranches.append(branch)
                continue
            }

            // Nested branch: process folder structure
            var currentPath = ""
            for i in 0..<(components.count - 1) { // Iterate folder components
                let component = components[i]
                let parentPath = currentPath
                currentPath = currentPath.isEmpty ? component : "\(currentPath)/\(component)" // Build full path key

                // Ensure entry exists for the current folder path
                if structure[currentPath] == nil {
                    structure[currentPath] = (subfolders: Set(), branches: [])
                }

                // Register this folder as a subfolder of its parent
                if parentPath.isEmpty {
                    rootFolders.insert(component) // Mark as a top-level folder
                } else {
                     // Add component to parent's subfolder set
                     structure[parentPath]?.subfolders.insert(component)
                }

                // If this is the immediate parent folder of the branch leaf
                if i == components.count - 2 {
                    structure[currentPath]?.branches.append(branch) // Add branch to its parent's list
                }
            }
        }

        // --- Recursive Helper Function ---
        func createNodes(folderName: String, path: String) -> BranchNode {
            var childNodes: [BranchNode] = []
            // Use empty defaults if path somehow doesn't exist in structure
            let data = structure[path] ?? (subfolders: Set(), branches: [])

            // Create nodes for subfolders (sorted alphabetically)
            for subfolder in data.subfolders.sorted() {
                childNodes.append(createNodes(folderName: subfolder, path: "\(path)/\(subfolder)"))
            }

            // Create nodes for direct branches (already sorted)
            for branch in data.branches {
                childNodes.append(BranchNode(branch: branch)) // Leaf node
            }

            // Return the folder node
            return BranchNode(name: folderName, children: childNodes) // children will be nil if empty via init
        }
        // --- End Recursive Helper ---

        // Build the final list of root nodes
        var rootNodes: [BranchNode] = []

        // Add root folders (sorted alphabetically)
        for folderName in rootFolders.sorted() {
            rootNodes.append(createNodes(folderName: folderName, path: folderName))
        }

        // Add root branches (already sorted)
        for branch in rootBranches {
            rootNodes.append(BranchNode(branch: branch)) // Root leaf node
        }

        return rootNodes
    }
}

struct BadgeView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(.systemGray))
            .cornerRadius(6)
            .foregroundColor(.primary)
    }
}

struct BranchTreeView: View {
    let branchNodes: [BranchNode] // Root nodes
    var body: some View {

            List(branchNodes, children: \.children) { node in
                BranchNodeRow(node: node)
                    .tag(node.branch?.id)

            }
            .scrollDisabled(true)
            .scrollIndicators(.hidden)
    }
}

// MARK: - Simplified Row View

// This view ONLY draws the content of a single row.
// List(children:) handles the expansion and hierarchy.
struct BranchNodeRow: View {
    let node: BranchNode
    // No need to pass Binding down here if selection is handled by .tag

    // --- Styling Properties ---
    private var iconName: String { node.isFolder ? "folder.fill" : "arrow.triangle.branch" }
    private var iconColor: Color { node.isFolder ? .secondary : .accentColor }
    private var fontWeight: Font.Weight { node.branch?.isCurrent == true ? .semibold : .regular }

    var body: some View {
        // Just the HStack for the row's content
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .resizable().aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16).foregroundColor(iconColor)
                .opacity(node.isFolder ? 0.7 : 1.0)

            Text(node.name) // Display name (folder or last part of branch)
                .fontWeight(fontWeight).lineLimit(1)
                .help(node.branch?.name ?? node.name) // Tooltip shows full name

            Spacer()

            if node.branch?.isCurrent == true {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green).font(.subheadline)
                    .help("Current Branch")
            }
        }
    }
}

