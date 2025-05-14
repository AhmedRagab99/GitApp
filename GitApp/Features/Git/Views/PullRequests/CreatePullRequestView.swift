import SwiftUI

struct CreatePullRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: GitViewModel

    @State private var title = ""
    @State private var description = ""
    @State private var selectedBaseBranch: String
    @State private var selectedHeadBranch: String
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(viewModel: GitViewModel) {
        self.viewModel = viewModel
        _selectedBaseBranch = State(initialValue: viewModel.currentBranch?.name ?? "main")
        _selectedHeadBranch = State(initialValue: viewModel.currentBranch?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)


                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                } header: {
                    Text("Pull Request Details")
                }

                Section {
                    Picker("Base Branch", selection: $selectedBaseBranch) {
                        ForEach(viewModel.branches, id: \.name) { branch in
                            Text(branch.name).tag(branch.name)
                        }
                    }

                    Picker("Head Branch", selection: $selectedHeadBranch) {
                        ForEach(viewModel.branches, id: \.name) { branch in
                            Text(branch.name).tag(branch.name)
                        }
                    }
                } header: {
                    Text("Branches")
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Create Pull Request")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPullRequest()
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
        }
    }

    private func createPullRequest() {
        guard !title.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil

        Task {
            await viewModel.createPullRequest(
                title: title,
                body: description,
                head: selectedHeadBranch,
                base: selectedBaseBranch
            )

            if let error = viewModel.pullRequestError {
                errorMessage = error
            } else {
                dismiss()
            }

            isSubmitting = false
        }
    }
}

#Preview {
    CreatePullRequestView(viewModel: GitViewModel())
}
