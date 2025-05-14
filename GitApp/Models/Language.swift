//
//  Language.swift
//  GitApp
//
//  Created by Ahmed Ragab on 20/04/2025.
//


import Foundation

import SwiftUI

enum Language: String, CaseIterable {
    case swift = "swift"
    case objectiveC = "m"
    case java = "java"
    case kotlin = "kt"
    case python = "py"
    case javascript = "js"
    case typescript = "ts"
    case c = "c"
    case cpp = "cpp"
    case csharp = "cs"
    case go = "go"
    case rust = "rs"
    case ruby = "rb"
    case php = "php"
    case html = "html"
    case css = "css"
    case json = "json"
    case yaml = "yaml"
    case xml = "xml"
    case markdown = "md"
    case shell = "sh"
    case other = "other"

    var displayName: String {
        switch self {
        case .swift: return "Swift"
        case .objectiveC: return "Objective-C"
        case .java: return "Java"
        case .kotlin: return "Kotlin"
        case .python: return "Python"
        case .javascript: return "JavaScript"
        case .typescript: return "TypeScript"
        case .c: return "C"
        case .cpp: return "C++"
        case .csharp: return "C#"
        case .go: return "Go"
        case .rust: return "Rust"
        case .ruby: return "Ruby"
        case .php: return "PHP"
        case .html: return "HTML"
        case .css: return "CSS"
        case .json: return "JSON"
        case .yaml: return "YAML"
        case .xml: return "XML"
        case .markdown: return "Markdown"
        case .shell: return "Shell"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .swift: return "swift"
        case .objectiveC: return "c.circle"
        case .java: return "j.circle"
        case .kotlin: return "k.circle"
        case .python: return "p.circle"
        case .javascript: return "js.circle"
        case .typescript: return "ts.circle"
        case .c: return "c.circle"
        case .cpp: return "cpp.circle"
        case .csharp: return "csharp.circle"
        case .go: return "g.circle"
        case .rust: return "r.circle"
        case .ruby: return "ruby.circle"
        case .php: return "php.circle"
        case .html: return "html.circle"
        case .css: return "css.circle"
        case .json: return "json.circle"
        case .yaml: return "yaml.circle"
        case .xml: return "xml.circle"
        case .markdown: return "markdown.circle"
        case .shell: return "terminal.circle"
        case .other: return "doc.circle"
        }
    }


    func color(for line: String) -> SwiftUI.Color {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

        // Common keywords and patterns
        if trimmedLine.isEmpty {
            return .clear
        }

        // Comments
        if trimmedLine.hasPrefix("//") || trimmedLine.hasPrefix("#") || trimmedLine.hasPrefix("/*") {
            return .gray
        }

        // Strings
        if trimmedLine.contains("\"") || trimmedLine.contains("'") {
            return .green
        }

        // Numbers
        if trimmedLine.range(of: #"^\d+$"#, options: .regularExpression) != nil {
            return .blue
        }

        return .primary
    }

    static func language(for fileExtension: String) -> Language {
        return Language(rawValue: fileExtension.lowercased()) ?? .other
    }
}
