//
//  FileDiff.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation
import SwiftUI
enum FileStatus: String {
    case modified = "Modified"
    case added = "Added"
    case removed = "Removed"
    case renamed = "Renamed"
    case copied = "Copied"
    case unknown = "Unknown"
    case untracked = "Untracked"
    case ignored = "Ignored"
    case deleted = "Deleted"

    

    var icon: String {
        switch self {
        case .added: return "plus.circle.fill"
        case .modified: return "pencil.circle.fill"
        case .deleted: return "minus.circle.fill"
        case .renamed: return "arrow.right.circle.fill"
        case .untracked: return "questionmark.circle.fill"
        case .ignored: return "questionmark.circle.fill"
        case .copied: return "doc.on.doc.fill"
        case .removed: return "minus.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .added: return .green
        case .modified: return .blue
        case .deleted: return .red
        case .renamed: return .orange
        case .untracked: return .gray
        case .ignored:
            return .gray
        case .removed:
            return .red
        case .copied:
            return .yellow
        case .unknown:
            return .gray
        }
    }

    var shortDescription: String {
        switch self {
        case .modified: return "M"
        case .added: return "A"
        case .removed: return "R"
        case .renamed: return "Ren"
        case .copied: return "C"
        case .unknown: return "?"
        case .untracked: return "U"
        case .ignored: return "I"
        case .deleted: return "D"
        }
    }
}

struct FileDiff: Identifiable, Hashable {
    var id: String { raw }
    var header: String
    var status: FileStatus {
        if fromFilePath.isEmpty && !toFilePath.isEmpty {
            return .added
        } else if !fromFilePath.isEmpty && toFilePath.isEmpty {
            return .removed
        } else if fromFilePath != toFilePath {
            return .renamed
        } else {
            return .modified
        }
    }

    var fromFilePath: String {
        let components = header.components(separatedBy: " ")
        guard components.count > 2 else {
            return ""
        }
        let filePath = components[2].dropFirst(2)
        return String(filePath)
    }

    var toFilePath: String {
        let components = header.components(separatedBy: " ")
        guard components.count > 3 else {
            return ""
        }
        let filePath = components[3].dropFirst(2)
        return String(filePath)
    }

    var filePathDisplay: String {
        if fromFilePath == toFilePath {
            return fromFilePath
        }
        if !fromFilePath.isEmpty && !toFilePath.isEmpty && fromFilePath != toFilePath {
            return fromFilePath + " => " + toFilePath
        }
        return ""
    }

    var extendedHeaderLines: [String]
    var fromFileToFileLines: [String]
    var chunks: [Chunk]
    var stage: Bool?
    var stageString: String {
        if let stage, stage {
            return "y"
        }
        return "n"
    }
    var unstageString: String {
        if let stage, !stage {
            return "y"
        }
        return "n"
    }
    var raw: String = ""

    private static func extractChunks(from lines: [String]) -> [String] {
        var chunks: [String] = []
        var currentChunk: String?

        for line in lines {
            if line.starts(with: "@@") {
                if let hunk = currentChunk {
                    chunks.append(hunk)
                }
                currentChunk = line
            } else {
                currentChunk?.append("\n" + line)
            }
        }

        if let lastHunk = currentChunk {
            chunks.append(lastHunk)
        }

        return chunks
    }

    init(raw: String) throws  {
        self.raw = raw
        let splited = raw.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        let firstLine = splited.first
        guard let firstLine else {
            throw GenericError(errorDescription: "Parse error for first line in FileDiff")
        }
        header = firstLine
        let fromFileIndex = splited.firstIndex { $0.hasPrefix("--- ") }
        guard let fromFileIndex else {
            extendedHeaderLines = splited[1..<splited.endIndex].map { String($0) }
            fromFileToFileLines = []
            chunks = []
            return
        }
        extendedHeaderLines = splited[1..<fromFileIndex].map { String($0) }
        let toFileIndex = splited.lastIndex { $0.hasPrefix("+++ ") }
        guard let toFileIndex else {
            throw GenericError(errorDescription: "Parse error for toFileIndex in FileDiff")
        }
        fromFileToFileLines = splited[fromFileIndex...toFileIndex].map { String($0) }
        chunks = Self.extractChunks(from: splited).map { Chunk(raw: $0) }
    }

    func updateAll(stage: Bool) -> Self {
        guard !chunks.isEmpty else {
            var newSelf = self
            newSelf.stage = stage
            return newSelf
        }
        let newChunks = chunks.map { chunk in
            var newChunk = chunk
            newChunk.stage = stage
            return newChunk
        }
        var new = self
        new.chunks = newChunks
        return new
    }

    func stageStrings() -> [String] {
        guard !chunks.isEmpty else {
            return [stageString]
        }
        return chunks.map { $0.stageString }
    }

    func unstageStrings() -> [String] {
        guard !chunks.isEmpty else {
            return [unstageString]
        }
        return chunks.map { $0.unstageString }
    }
}
