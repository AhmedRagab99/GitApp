import SwiftUI

struct PullRequestListView: View {
    @Bindable var viewModel: GitViewModel
    @State private var selectedFilter: PullRequestState?
    @State private var searchText = ""
    @State private var selectedPR: PullRequest?

    var filteredPRs: [PullRequest] {
        viewModel.pullRequests.filter { pr in
            let matchesFilter = selectedFilter == nil || pr.state == selectedFilter
            let matchesSearch = searchText.isEmpty ||
                pr.title.localizedCaseInsensitiveContains(searchText) ||
                pr.description.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar with filters
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search pull requests", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top)

                // Filter buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterButton(title: "All", isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }
                        FilterButton(title: "Open", isSelected: selectedFilter == .open) {
                            selectedFilter = .open
                        }
                        FilterButton(title: "Closed", isSelected: selectedFilter == .closed) {
                            selectedFilter = .closed
                        }
                        FilterButton(title: "Merged", isSelected: selectedFilter == .merged) {
                            selectedFilter = .merged
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                // PR List
                if viewModel.isLoadingPullRequests {
                    ProgressView("Loading pull requests...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.pullRequestError {
                    ContentUnavailableView {
                        Label("Error Loading Pull Requests", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task {
                                await viewModel.loadPullRequests()
                            }
                        }
                    }
                } else if filteredPRs.isEmpty {
                    ContentUnavailableView {
                        Label("No Pull Requests", systemImage: "arrow.triangle.pull")
                    } description: {
                        Text("There are no pull requests matching your filters")
                    }
                } else {
                    List(filteredPRs, selection: $selectedPR) { pr in
                        PullRequestRow(pullRequest: pr)
                            .onTapGesture {
                                selectedPR = pr
                                Task {
                                    await viewModel.loadPullRequestDetails(pr)
                                }
                            }
                    }
                    .listStyle(.plain)
                }
            }
        } detail: {
            if let selectedPR = selectedPR {
                PullRequestDetailView(pullRequest: selectedPR)
            } else {
                ContentUnavailableView("Select a Pull Request",
                    systemImage: "arrow.triangle.pull",
                    description: Text("Choose a pull request from the list to view its details")
                )
            }
        }
        .navigationTitle("Pull Requests")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { /* TODO: Create new PR */ }) {
                    Label("New Pull Request", systemImage: "plus")
                }
            }
        }
        .task {
            await viewModel.loadPullRequests()
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.textBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct PullRequestRow: View {
    let pullRequest: PullRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: pullRequest.state.icon)
                    .foregroundColor(Color(pullRequest.state.color))
                Text("#\(pullRequest.number)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(pullRequest.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                PullRequestStatusBadge(status: pullRequest.state)
            }

            HStack {
                Label(pullRequest.author, systemImage: "person")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Label(pullRequest.files.count.formatted(), systemImage: "doc")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label(pullRequest.comments.count.formatted(), systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PullRequestStatusBadge: View {
    let status: PullRequestState

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .cornerRadius(6)
    }
}
