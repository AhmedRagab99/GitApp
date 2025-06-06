//
//  GitCommitAmend.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//

import Foundation

struct GitCommitAmend: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        [
            "git",
            "commit",
            "--amend",
            "-m",
            message,
        ]
    }
    var directory: URL
    var message: String

    func parse(for stdOut: String) -> Void {}
}
