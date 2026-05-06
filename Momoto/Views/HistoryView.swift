//
//  HistoryView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI

// Inputs
struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    let onTap: (MindMap) -> Void

    // MARK: Main page
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            if viewModel.history.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .onAppear {
            viewModel.load()
        }
        .navigationTitle("Recent Mindmaps")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "Search mindmap")
        
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
                ForEach(viewModel.filteredHistory) { entry in
                    HistoryCard(
                        entry: entry,
                        onTap: { viewModel.handleTap(on: entry, tapAction: onTap) },
                        onDelete: { viewModel.handleDelete(for: entry) },
                        isDeleteMode: viewModel.isDeleteMode,
                        isSelected: viewModel.selectedDeleteID.contains(entry.id)
                    )
                }

                if viewModel.filteredHistory.isEmpty && !viewModel.searchText.isEmpty {
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
                .font(.system(.largeTitle, design: .rounded).weight(.light))
                .foregroundStyle(Theme.purple)
            
            Text("No mindmap available")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 248)
    }
    
    // 3. No search result
    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(.largeTitle, design: .rounded).weight(.light))
                .foregroundStyle(Theme.purple.opacity(0.5))
            
            Text("No results for \"\(viewModel.searchText)\"")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    // 5. Toolbar delete button
    @ToolbarContentBuilder
    private var deleteButton: some ToolbarContent {
        if !viewModel.history.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.toggleDeleteMode() }) {
                    Image(systemName: viewModel.isDeleteMode ? "xmark" : "trash")
                        .foregroundStyle(Theme.red)
                }
                .accessibilityLabel(viewModel.isDeleteMode ? "Cancel delete" : "Delete mindmap")
            }
        }
    }
    
    // 6. Bottom delete button
    @ViewBuilder
    private var confirmDeleteButton: some View {
        if viewModel.isDeleteMode, !viewModel.selectedDeleteID.isEmpty {
            Button("Delete Now", role: .destructive, action: { viewModel.deleteSelected() })
                .buttonStyle(PrimaryButtonStyle(color: Theme.red, isFullWidth: true))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
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
            onTap: { _ in }
        )
    }
}
