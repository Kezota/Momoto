//
//  HistoryView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI

// Inputs
struct HistoryView: View {
    let history: [MindMap]
    let onTap: (MindMap) -> Void
    let onDelete: (UUID) -> Void
    
    @State private var isDeleteMode: Bool = false
    @State private var selectedDeleteID: Set<UUID> = []
    @State private var searchText: String = ""
    
    // Filter history
    private var filteredHistory: [MindMap] {
        if searchText.isEmpty { return history }
        return history.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: Main page
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.97, blue: 0.98)
                .ignoresSafeArea()
            
            if history.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    searchBar
                    historyList
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Recent Mindmaps")
        .navigationBarTitleDisplayMode(.large)
        
        // Top right: Delete button
        .toolbar { deleteButton }
        
        // Bottom: Confirm delete button
        .safeAreaInset(edge: .bottom) { confirmDeleteButton }
    }

    // MARK: UI
    // 1. Mindmap history
    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(filteredHistory) { entry in
                    HistoryCard(
                        entry: entry,
                        onTap: {
                            if isDeleteMode {
                                if !selectedDeleteID.insert(entry.id).inserted { selectedDeleteID.remove(entry.id) }
                            } else { onTap(entry) }
                        },
                        onDelete: { onDelete(entry.id) },
                        isDeleteMode: isDeleteMode,
                        isSelected: selectedDeleteID.contains(entry.id)
                    )
                }

                if filteredHistory.isEmpty && !searchText.isEmpty {
                    noResultsState
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
    
    // 2. No mindmap available
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color(red: 0.45, green: 0.34, blue: 0.92))
            
            Text("No mindmap available")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 248)
    }
    
    // 3. No search result
    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color(red: 0.45, green: 0.34, blue: 0.92).opacity(0.5))
            
            Text("No results for \"\(searchText)\"")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    // 4. Search bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search mindmap", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
    
    // 5. Toolbar delete button
    @ToolbarContentBuilder
    private var deleteButton: some ToolbarContent {
        if !history.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: toggleDeleteMode) {
                    Image(systemName: isDeleteMode ? "xmark" : "trash")
                        .foregroundStyle(Color(red: 0.45, green: 0.34, blue: 0.92)) //purple
                }
                .accessibilityLabel(isDeleteMode ? "Cancel delete" : "Delete mindmap")
            }
        }
    }
    
    // 6. Bottom delete button
    private var confirmDeleteButton: some View {
        Group {
            if isDeleteMode, !selectedDeleteID.isEmpty {
                Button("Delete Now", role: .destructive, action: deleteSelected)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: Helper Functions
    private func toggleDeleteMode() {
        isDeleteMode.toggle()
        if !isDeleteMode { selectedDeleteID.removeAll() }
    }

    private func deleteSelected() {
        selectedDeleteID.forEach(onDelete)
        selectedDeleteID.removeAll()
        isDeleteMode = false
    }
}

// MARK: - Preview

#Preview {
    let sampleHistory: [MindMap] = [
        MindMap(
            id: UUID(),
            title: "Dessert recipes analysis",
            root: MindMapNode(title: "Dessert"),
            rawText: "",
            createdAt: .now,
            source: ""
        ),
        MindMap(
            id: UUID(),
            title: "Debug session notes",
            root: MindMapNode(title: "Debug"),
            rawText: "",
            createdAt: .now,
            source: ""
        )
    ]
    
    NavigationStack {
        HistoryView(
            history: sampleHistory,
            onTap: { _ in },
            onDelete: { _ in }
        )
    }
}
