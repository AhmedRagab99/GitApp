//
//  ConflictLineView.swift
//  GitApp
//
//  Created by Ahmed Ragab on 13/06/2025.
//
import SwiftUI

struct ConflictLineView: View {
    let line: Line

    var body: some View {
        ListRow(
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
            backgroundColor: conflictBackground(line),
            cornerRadius: 0,
            shadowRadius: 0
        ) {
            HStack {
                if line.kind == .conflictStart {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.trailing, 4)
                } else if line.kind == .conflictOurs {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.blue)
                        .font(.caption)
                        .padding(.trailing, 4)
                } else if line.kind == .conflictTheirs {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.green)
                        .font(.caption)
                        .padding(.trailing, 4)
                }

                Text(line.raw)
                    .font(.system(.body, design: .monospaced))
                    .padding(.vertical, 1.5)
                    .foregroundColor(conflictTextColor(line))
                Spacer()
            }
            .padding(.horizontal, 8)
        }
    }

    func conflictBackground(_ line: Line) -> Color {
        switch line.kind {
        case .conflictOurs: return Color.blue.opacity(0.1)
        case .conflictTheirs: return Color.green.opacity(0.1)
        case .conflictStart, .conflictMiddle, .conflictEnd: return Color.red.opacity(0.1)
        default: return .clear
        }
    }

    func conflictTextColor(_ line: Line) -> Color {
        switch line.kind {
        case .conflictOurs: return .blue
        case .conflictTheirs: return .green
        case .conflictStart, .conflictMiddle, .conflictEnd: return .red
        default: return .primary
        }
    }
}
