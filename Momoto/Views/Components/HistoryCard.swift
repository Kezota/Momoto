//
//  HistoryCard.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI

struct HistoryCard: View {
    let entry: MindMap
    let onTap: () -> Void
    let onDelete: () -> Void
    let isDeleteMode: Bool
    let isSelected: Bool
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                
                // Left: Mindmap icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.greenSoft)
                        .frame(width: 52, height: 52)
                    Image(systemName: entry.root.symbol)
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.green)
                }
                
                // Middle: Texts
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        Text(entry.createdAt, style: .date)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                // Right: Arrow
                Spacer(minLength: 0)
                Image(systemName: isDeleteMode ? (isSelected ? "checkmark.circle.fill" : "circle") : "chevron.right")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(isSelected ? Theme.red : Theme.textSecondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isDeleteMode ? Theme.white.opacity(0.85) : Theme.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Theme.stroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        
        // Delete Action
        .swipeActions {
            if !isDeleteMode {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .contextMenu {
            if !isDeleteMode {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
