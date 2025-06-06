//
//  GitStashShowDiff.swift
//  GitClient
//
//

import Foundation

struct GitStashShowDiff: Git {
    typealias OutputModel = String
    var arguments: [String] {
        [
            "git",
            "stash",
            "show",
            "--include-untracked",
            "-p",
            "\(index)",
        ]
    }
    var directory: URL
    var index: Int

    func parse(for stdOut: String) -> String {
        stdOut
    }
}
