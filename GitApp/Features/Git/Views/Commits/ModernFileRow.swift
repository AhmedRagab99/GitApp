//
//  ModernFileRow.swift
//  GitApp
//
//  Created by Ahmed Ragab on 10/05/2025.
//

import SwiftUI
// MARK: - Modern File Row
struct ModernFileRow: View {
    let fileDiff: FileDiff
    let isSelected: Bool
    let actionIcon: String
    let actionColor: Color
    let action: () -> Void
    @State private var isHovered: Bool = false
    var onStage: (() -> Void)? = nil
    var onUnstage: (() -> Void)? = nil
    var onReset: (() -> Void)? = nil
    var onIgnore: (() -> Void)? = nil
    var onTrash: (() -> Void)? = nil
    var onResolveWithMine: (() -> Void)? = nil
    var onResolveWithTheirs: (() -> Void)? = nil
    var onMarkAsResolved: (() -> Void)? = nil
    var isStaged: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            statusIcon
            fileInfo
            Spacer()
            rightSideContent
        }
        .padding(10)
        .background(background)
        .overlay(border)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .onHover { hovering in isHovered = hovering }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fileDiff.fromFilePath), status: \(fileDiff.status.rawValue)")
        .help(helpText)
        .contextMenu{ menu}
    }

    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(fileDiff.status.color.opacity(0.18))
                .frame(width: 28, height: 28)
            Image(systemName: fileDiff.status.icon)
                .foregroundStyle(fileDiff.status.color)
                .font(.system(size: 15, weight: .medium))
        }
    }

    private var fileInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath.components(separatedBy: "/").last ?? "" : fileDiff.fromFilePath.components(separatedBy: "/").last ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .primary : .secondary)
            Text(fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var rightSideContent: some View {
        if fileDiff.status == .conflict {
            conflictResolutionButtons
        } else {
            lineStatsView
        }
        StatusBadge(status: fileDiff.status)
        mainActionButton
    }

    private var conflictResolutionButtons: some View {
        HStack(spacing: 8) {
            Button(action: { onResolveWithMine?() }) {
                Label("Keep Mine", systemImage: "person.circle")
            }
            .help("Resolve conflict by keeping your changes")

            Button(action: { onResolveWithTheirs?() }) {
                Label("Take Theirs", systemImage: "person.2.circle")
            }
            .help("Resolve conflict by taking their changes")

            Button(action: { onMarkAsResolved?() }) {
                Label("Mark Resolved", systemImage: "checkmark.circle")
            }
            .help("Mark this file as resolved")
        }
        .buttonStyle(.bordered)
    }

    private var lineStatsView: some View {
        HStack {
            if fileDiff.lineStats.added > 0 {
                Text("+\(fileDiff.lineStats.added)")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
                    .padding(.horizontal, 4)
            }
            if fileDiff.lineStats.removed > 0 {
                Text("-\(fileDiff.lineStats.removed)")
                    .font(.caption2.bold())
                    .foregroundStyle(.red)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var mainActionButton: some View {
        Button(action: action) {
            Image(systemName: actionIcon)
                .foregroundStyle(actionColor)
                .font(.system(size: 18))
        }
        .buttonStyle(.plain)
        .opacity(isHovered ? 1 : 0.7)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color.accentColor.opacity(0.18) : (isHovered ? Color.accentColor.opacity(0.08) : Color(.windowBackgroundColor).opacity(0.7)))
            .shadow(color: isSelected ? Color.accentColor.opacity(0.10) : .clear, radius: 2, x: 0, y: 1)
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(isSelected ? Color.accentColor : Color(.systemGray).opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
    }

    private var helpText: String {
        """
        Status: \(fileDiff.status.rawValue) (\(fileDiff.status.shortDescription))
        From: \(fileDiff.fromFilePath.isEmpty ? "None" : fileDiff.fromFilePath)
        To: \(fileDiff.toFilePath.isEmpty ? "None" : fileDiff.toFilePath)
        Lines Added: \(fileDiff.lineStats.added)
        Lines Removed: \(fileDiff.lineStats.removed)
        Header: \(fileDiff.header)
        """
    }

    @ViewBuilder
    private var menu: some View {
        if let onStage = onStage {
            Button {
                onStage()
            } label: {
                Label("Stage File", systemImage: "plus.circle")
            }
        }

        if let onUnstage = onUnstage {
            Button {
                onUnstage()
            } label: {
                Label("Unstage File", systemImage: "minus.circle")
            }
        }

        if let onReset = onReset {
            Button {
                onReset()
            } label: {
                Label("Reset File (Discard Changes)", systemImage: "arrow.counterclockwise")
            }
            .foregroundColor(.red)
        }

        if fileDiff.status == .conflict, let onResolveWithMine = onResolveWithMine, let onResolveWithTheirs = onResolveWithTheirs, let onMarkAsResolved = onMarkAsResolved {
            Divider()
            Button { onResolveWithMine() } label: {
                Label("Resolve: Keep My Version", systemImage: "person.circle")
            }
            Button { onResolveWithTheirs() } label: {
                Label("Resolve: Take Their Version", systemImage: "person.2.circle")
            }
            Divider()
            Button { onMarkAsResolved() } label: {
                Label("Mark as Resolved", systemImage: "checkmark.circle")
            }
        }

        Divider()

        if let onIgnore = onIgnore {
            Button {
                onIgnore()
            } label: {
                Label("Add to .gitignore", systemImage: "eye.slash")
            }
        }

        if let onTrash = onTrash {
            Button(role: .destructive) {
                onTrash()
            } label: {
                Label("Move to Trash", systemImage: "trash")
            }
        }

        Divider()

        Button {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(fileDiff.fromFilePath.isEmpty ? fileDiff.toFilePath : fileDiff.fromFilePath, forType: .string)
        } label: {
            Label("Copy Path", systemImage: "doc.on.clipboard")
        }
    }
}
