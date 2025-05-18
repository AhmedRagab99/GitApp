import SwiftUI
import Combine
import Foundation
import Observation

@Observable
class GitViewModel {
    // --- Published Properties (State) ---
     var repoInfo: RepoInfo = RepoInfo()
     var branches: [Branch] = []
     var remotebranches: [Branch] = []
     var tags: [Tag] = []
     var stashes: [Stash] = []
     var workspaceCommands: [WorkspaceCommand] = []
     var selectedSidebarItem: AnyHashable?
     var selectedCommit: Commit?
     var selectedFileDiff: FileDiff?
     var diffContent: Diff?
     var isLoading: Bool = false
     var errorMessage: String?
     var repositoryURL: URL? {
        didSet {
            if let url = repositoryURL {
                Task {
                    await loadRepositoryData(from: url)
                }
            }
        }
    }

    // Search related properties
    var searchText: String = ""
    var searchAuthor: String = ""
    var searchContent: String = ""
    var searchAllMatch: Bool = false

     var isSearchingRepositories = false
     var selectedBranch: Branch? {
        didSet {
            if let branch = selectedBranch, let url = repositoryURL {
                loadCommits(for: branch, in: url)
            }
        }
    }
     var currentBranch: Branch?
     var commitDetails: CommitDetails?
     var stagedDiff: Diff?
     var unstagedDiff: Diff?
     var untrackedFiles: [String] = []

    var syncState = SyncState()
    var commits = [Commit]()

    // Add LogStore
    let logStore = LogStore()

    struct ImportProgress: Identifiable {
        let id = UUID()
        var current: Int
        var total: Int
        var status: String
    }

    private var cancellables = Set<AnyCancellable>()
    private let gitService = GitService()

    init() {

        loadWorkspaceCommands()

    }

    func isGitRepository(at: URL) async -> Bool {
            return  await gitService.isGitRepository(at: at)
    }

    private func loadWorkspaceCommands() {
        workspaceCommands = [
            WorkspaceCommand(name: "Fetch", icon: "arrow.triangle.2.circlepath"),
            WorkspaceCommand(name: "Pull", icon: "arrow.down.circle"),
            WorkspaceCommand(name: "Push", icon: "arrow.up.circle"),
            WorkspaceCommand(name: "Commit", icon: "checkmark.circle")
        ]
    }

    // --- Public Methods ---
    func loadRepositoryData(from url: URL) async {
        do {
            guard  await gitService.isGitRepository(at: url) else {
                errorMessage = "Selected directory is not a Git repository"
                return
            }

            isLoading = true
            defer { isLoading = false }

            // Load data in parallel where possible
            async let branchesTask = gitService.getBranches(in: url)
            async let currentBranchTask = gitService.getCurrentBranch(in: url)
            async let tagsTask = gitService.getTags(in: url)
            async let stashesTask = gitService.getStashes(in: url)
            async let remotesTask = gitService.getRemotes(in: url)

            // Wait for all parallel tasks to complete
            let (branches, currentBranchName, tags, stashes, remotes) = try await (
                branchesTask,
                currentBranchTask,
                tagsTask,
                stashesTask,
                remotesTask
            )

            // Update branches
            self.branches = branches
            self.remotebranches = remotes

            // Set current branch and update related state
            if let currentBranchName = currentBranchName {
                currentBranch = branches.first { $0.name == currentBranchName }
                selectedBranch = currentBranch
                await MainActor.run {
                    syncState.branch = currentBranch
                    syncState.folderURL = url

                    // Update LogStore with current branch
                    logStore.directory = url
                    logStore.searchTokens = [SearchToken(kind: .revisionRange, text: currentBranchName)]
                }
                await logStore.refresh()
            }

            // Update other repository data
            self.tags = tags
            self.stashes = stashes

            // Update repository info
            repoInfo = RepoInfo(
                name: url.lastPathComponent,
                currentBranch: currentBranchName ?? "main",
                remotes: remotes
            )

            // Check sync state
            try await syncState.sync()

        } catch {
            errorMessage = "Error loading repository data: \(error.localizedDescription)"
        }
    }

    private func gatherRepositoryInfo(from url: URL) async -> RepoInfo {
        do {
            // Get repository name
            let name = url.lastPathComponent

            // Get current branch
            let currentBranch = try await gitService.getCurrentBranch(in: url) ?? "main"

            // Get remote information
            let remotes = try await gitService.getRemotes(in: url)

            return RepoInfo(
                name: name,
                currentBranch: currentBranch,
                remotes: remotes
            )
        } catch {
            errorMessage = "Error gathering repository info: \(error.localizedDescription)"
            return RepoInfo()
        }
    }

    private func loadCommits(for branch: Branch, in url: URL) {
        Task {
                isLoading = true
                defer { isLoading = false }

                // Update LogStore with branch
                logStore.directory = url
                logStore.searchTokens = [SearchToken(kind: .revisionRange, text: branch.name)]
                await logStore.refresh()

        }
    }




    // --- Git Actions ---
    func performFetch() async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await gitService.fetch(in: url)
            // Refresh repository data
            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Fetch failed: \(error.localizedDescription)"
        }
    }

    /// Create a new stash with message and keepStaged option
       func createStash(message: String, keepStaged: Bool) async {
           guard let url = repositoryURL else { return }
           isLoading = true
           defer { isLoading = false }
           do {
               try await gitService.createStash(message, in: url, keepStaged: keepStaged)
               await loadRepositoryData(from: url)
           } catch {
               errorMessage = "Error creating stash: \(error.localizedDescription)"
           }
       }

       /// Apply a stash by index
       func applyStash(at index: Int) async {
           guard let url = repositoryURL else { return }
           isLoading = true
           defer { isLoading = false }
           do {
               try await gitService.applyStash(index, in: url)
               await loadRepositoryData(from: url)
           } catch {
               errorMessage = "Error applying stash: \(error.localizedDescription)"
           }
       }

    func performPull() async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await gitService.pull(in: url)
            // Refresh repository data
            await refreshState()
//            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Pull failed: \(error.localizedDescription)"
        }
    }

    func pull(remote: String, remoteBranch: String, localBranch: String, options: PullSheet.PullOptions) async {
        guard let url = repositoryURL else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            // You may need to update your gitService.pull to accept these options and pass the correct arguments
            try await gitService.pull(
                in: url,
                remote: remote,
                remoteBranch: remoteBranch,
                localBranch: localBranch,
                commitMerged: options.commitMerged,
                includeMessages: options.includeMessages,
                createNewCommit: options.createNewCommit,
                rebaseInsteadOfMerge: options.rebaseInsteadOfMerge
            )
            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Pull failed: \(error.localizedDescription)"
        }
    }


    func performPush() async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await gitService.push(in: url,refspec: currentBranch?.name ?? "HEAD")
            syncState.commitsAhead =  0
            await refreshState()
        } catch {
            errorMessage = "Push failed: \(error.localizedDescription)"
        }
    }

    func performCommit() async {
        errorMessage = "Commit functionality not implemented yet"
    }




    func loadCommitDetails(_ commit: Commit, in url: URL) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Get full commit details
             let details = try await gitService.getCommitDetails(commit.hash, in: url)
                commitDetails = details

        } catch {
            errorMessage = "Error loading commit details: \(error.localizedDescription)"
        }
    }



    func loadChanges() async {
        guard let url = repositoryURL else { return }
        do {
            let status = try await gitService.getStatus(in: url)

            // Get staged changes
            let stagedDiff = try await gitService.getDiff(in: url, cached: true)
            self.stagedDiff = stagedDiff

            // Get unstaged changes
            let unstagedDiff = try await gitService.getDiff(in: url, cached: false)
            self.unstagedDiff = unstagedDiff

            // Update untracked files
            self.untrackedFiles = status.untrackedFiles


            // Update selected file diff if needed
            if let selectedPath = selectedFileDiff?.fromFilePath {
                if let stagedFile = stagedDiff.fileDiffs.first(where: { $0.fromFilePath == selectedPath }) {
                    selectedFileDiff = stagedFile
                } else if let unstagedFile = unstagedDiff.fileDiffs.first(where: { $0.fromFilePath == selectedPath }) {
                    selectedFileDiff = unstagedFile
                }
            }
        } catch {

            errorMessage = "Error loading changes: \(error)"
        }
    }

    func stageChunk(_ chunk: Chunk, in fileDiff: FileDiff) {
        guard let url = repositoryURL else { return }

        Task {
            do {
               try await gitService.stageChunk(chunk, in: fileDiff, directory: url)
                await loadChanges()
            } catch {
                errorMessage = "Error staging chunk: \(error.localizedDescription)"
            }
        }
    }

    func unstageChunk(_ chunk: Chunk, in fileDiff: FileDiff) {
        guard let url = repositoryURL else { return }

        Task {
            do {
                try await gitService.unstageChunk(chunk, in: fileDiff, directory: url)
                await loadChanges()
            } catch {
                errorMessage = "Error unstaging chunk: \(error.localizedDescription)"
            }
        }
    }

    func unstageFile(path: String) async {
        guard let url = repositoryURL else { return }

        do {
            try await gitService.unstageFile(path, in: url)
            await loadChanges()
        } catch {
            errorMessage = "Error unstaging file: \(error.localizedDescription)"
        }
    }

    func stageFile(path: String) async {
        guard let url = repositoryURL else { return }

        do {
            try await gitService.addFiles(in: url, pathspec: path)
            await loadChanges()
        } catch {
            errorMessage = "Error staging file: \(error.localizedDescription)"
        }
    }

    func resetChunk(_ chunk: Chunk, in fileDiff: FileDiff) {
        guard let url = repositoryURL else { return }

        Task {
            do {
                try await gitService.resetChunk(chunk, in: fileDiff, directory: url)
                await loadChanges()
            } catch {
                errorMessage = "Error resetting chunk: \(error.localizedDescription)"
            }
        }
    }

    func stageAllChanges() async {
            do {
                guard let url = repositoryURL else { return }
                try await gitService.stageAllChanges(in: url)
                await loadChanges()
            } catch {
                errorMessage = "Error staging changes: \(error.localizedDescription)"
            }
    }

    func unstageAllChanges() async {
        guard let url = repositoryURL else { return }
            do {
                try await gitService.unstageAllChanges(in: url)
                await loadChanges()
            } catch {
                errorMessage = "Error unstaging all changes: \(error.localizedDescription)"
            }

    }

    func commitChanges(message: String) async {
        guard let url = repositoryURL else { return }
        do {
            isLoading = true
            defer { isLoading = false }

            try await gitService.commitChanges(in: url, message: message)

            // Reload repository data
            await refreshState()
        } catch {
            errorMessage = "Error committing changes: \(error.localizedDescription)"
        }
    }

    func checkoutBranch(_ branch: Branch,isRemote: Bool = false) async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            currentBranch = branch
            selectedBranch = branch
            syncState.branch = branch


            if isRemote {
                try await gitService.checkoutBranch(to: branch, in: url)
                updateDataFromRemoteCheckout(from: branch)

            } else {
                try await gitService.switchBranch(to: branch.name, in: url)
            }

            updateDataFromLocalCheckout()



            await loadChanges()
        } catch {
            errorMessage = "Checkout failed: \(error.localizedDescription)"
        }
    }

    private func updateDataFromLocalCheckout() {
        self.branches = branches.map { branch in
            var updatedBranch = branch
            updatedBranch.isCurrent = branch.name == currentBranch?.name ?? ""
            return updatedBranch
        }
    }

    private func updateDataFromRemoteCheckout(from branch: Branch) {
        self.remotebranches.removeAll(where: {$0.name == branch.name})

        var tempBranch = branch
        tempBranch.isCurrent = true
        self.branches.append(tempBranch)
    }


    func refreshState() async {
        guard let url = repositoryURL else { return }

        isLoading = true
        defer { isLoading = false }


            // Refresh repository data
            await loadRepositoryData(from: url)

            // Refresh changes
            await loadChanges()

            // Refresh current branch
//            if let currentBranchName = try await gitService.getCurrentBranch(in: url) {
//                currentBranch = branches.first { $0.name == currentBranchName }
//                selectedBranch = currentBranch

                // Update LogStore
                logStore.directory = url
//                logStore.searchTokens = [SearchToken(kind: .revisionRange, text: currentBranchName)]
                await logStore.refresh()
//            }

    }


    func selectRepository(_ url: URL) {
        repositoryURL = url
        Task {
            await loadRepositoryData(from: url)
        }
    }


    func checkoutCommit(_ hash: String) async {
        guard let repoURL = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        do {
            try await gitService.checkoutCommit(hash, in: repoURL)
            // Refresh the state
            await refreshState()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Branch Operations
    func switchBranch(to branch: Branch) async {
        guard let url = repositoryURL else { return }
        do {
            isLoading = true
            defer { isLoading = false }

            try await gitService.switchBranch(to: branch.name, in: url)
            currentBranch = branch
            selectedBranch = branch
            syncState.branch = branch

            // Update LogStore with new branch
            logStore.searchTokens = [SearchToken(kind: .revisionRange, text: branch.name)]
            await logStore.refresh()

            // Check sync state
            try await syncState.sync()
        } catch {
            errorMessage = "Error switching branch: \(error.localizedDescription)"
        }
    }

    // MARK: - Sync Operations

    func push() async {
        guard let url = repositoryURL else { return }
        do {
            isLoading = true
            defer { isLoading = false }

            try await gitService.push(in: url)
            try await syncState.sync()
        } catch {
            errorMessage = "Error pushing changes: \(error.localizedDescription)"
        }
    }



    func copyCommitHash(_ hash: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(hash, forType: .string)
    }

    func checkoutCommit(_ commit: Commit) {
        Task {
            do {
                guard let url = repositoryURL else { return }
                try await gitService.checkoutCommit(commit.hash, in: url)
                await loadRepositoryData(from: url)
            } catch {
                errorMessage = "Error checking out commit: \(error.localizedDescription)"
            }
        }
    }



    func loadCommitDetails(_ commit: Commit) {
        Task {
            guard let url = repositoryURL else { return }
            await loadCommitDetails(commit, in: url)
        }
    }

    /// Create a new branch and optionally check it out
    func createBranch(named name: String, checkout: Bool = true) async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            // Create the branch
            try await gitService.createBranch(name, in: url)
            // Optionally check out the new branch
            if checkout {
                try await gitService.switchBranch(to: name, in: url)

            }
            // Refresh branches and current branch state
            await loadRepositoryData(from: url)
//            updateDataFromLocalCheckout()
        } catch {
            errorMessage = "Error creating branch: \(error.localizedDescription)"
        }
    }

    /// Delete a stash by index
    func deleteStash(at index: Int) async {
        guard let url = repositoryURL else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await gitService.dropStash(index, in: url)
            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Error deleting stash: \(error.localizedDescription)"
        }
    }

    func push(branch: Branch, pushTags: Bool) async {
        guard let url = repositoryURL else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await gitService.push(in: url, refspec: branch.name, pushTags: pushTags)
            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Push failed: \(error.localizedDescription)"
        }
    }

    func deleteBranches(_ branches: [Branch], deleteRemote: Bool = false,isRemote: Bool = false) async {
        guard let url = repositoryURL else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            for branch in branches {
                if !isRemote {

                    // Delete local branch
                    try await gitService.deleteBranch(branch.name, in: url)

                    // Delete remote branch if requested
                    if deleteRemote {
                        try await gitService.deleteBranch(branch.name, in: url, isRemote: true)
                    }
                }
                else {
                    try await gitService.deleteBranch(branch.name, in: url, isRemote: true)
                }
            }

            // Refresh repository data
            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Error deleting branches: \(error.localizedDescription)"
        }
    }

    func renameBranch(_ branch: Branch, to newName: String) async {
        guard let url = repositoryURL else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try await gitService.renameBranch(branch.name, to: newName, in: url)
            await loadRepositoryData(from: url)
        } catch {
            errorMessage = "Error renaming branch: \(error.localizedDescription)"
        }
    }

    // MARK: - Search Operations

    func handleSearch(_ query: String) async {
        guard !query.isEmpty else {
            // Reset search when query is empty
            logStore.searchTokens = []
            await logStore.refresh()
            return
        }

        var searchTokens: [SearchToken] = []

        // Add message/content search
        if !query.isEmpty {
            searchTokens.append(SearchToken(kind: .grep, text: query))
        }

        // Add author search if specified
        if !searchAuthor.isEmpty {
            searchTokens.append(SearchToken(kind: .author, text: searchAuthor))
        }

        // Add content search if specified
        if !searchContent.isEmpty {
            searchTokens.append(SearchToken(kind: .s, text: searchContent))
        }

        // Set all match flag if needed
        if searchAllMatch {
            searchTokens.append(SearchToken(kind: .grepAllMatch, text: ""))
        }

        // Update search tokens and refresh
        logStore.searchTokens = searchTokens
        await logStore.refresh()
    }

    func resetSearch() async {
        searchText = ""
        searchAuthor = ""
        searchContent = ""
        searchAllMatch = false
        logStore.searchTokens = []
        await logStore.refresh()
    }

    // MARK: - Merge Operations
    func mergeBranch(
        _ branchName: String,
        commitMerged: Bool = true,
        includeMessages: Bool = false,
        createNewCommit: Bool = false,
        rebaseInsteadOfMerge: Bool = false
    ) async {
        guard let url = repositoryURL else {
            errorMessage = "No repository selected"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await gitService.merge(
                in: url,
                branchName: branchName,
                commitMerged: commitMerged,
                includeMessages: includeMessages,
                createNewCommit: createNewCommit,
                rebaseInsteadOfMerge: rebaseInsteadOfMerge
            )

            // Refresh repository data after merge
            await refreshState()
        } catch {
            errorMessage = "Merge failed: \(error.localizedDescription)"
        }
    }
}

extension GitViewModel {
    var pendingCommitsCount: Int {
        // If you have a better way to count pending commits, use it here
        stagedDiff?.fileDiffs.count ?? 0
    }

    var pendingPushCount: Int {
        // If you track commits ahead, use that here
        syncState.commitsAhead ?? 0
    }
}
