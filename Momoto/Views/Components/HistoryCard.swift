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
                        .fill(Color(red: 0.93, green: 0.90, blue: 1.00)) //purple
                        .frame(width: 52, height: 52)
                    Image(systemName: "brain") // icon per mindmap sementara
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color(red: 0.45, green: 0.34, blue: 0.92)) //light purple
                }
                
                // Middle: Texts
                VStack(alignment: .leading, spacing: 5) {
                    //Title
                    Text(entry.title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
                        // Source blom ada di models
                        // Date
                        Text(entry.createdAt, style: .date)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Right: Arrow
                Spacer(minLength: 0)
                Image(systemName: isDeleteMode ? (isSelected ? "checkmark.circle.fill" : "circle") : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .red : .secondary)
            }
            // Background
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isDeleteMode ? Color.white.opacity(0.85) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
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
