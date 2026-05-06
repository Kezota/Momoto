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
                HistoryEmptyState()
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
                    HistoryNoResultsState(searchText: viewModel.searchText)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }
    

    // 5. Toolbar delete button
    @ToolbarContentBuilder
    private var deleteButton: some ToolbarContent {
        if !viewModel.history.isEmpty {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.toggleDeleteMode() }) {
                    if viewModel.isDeleteMode {
                        Text("Cancel")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                    } else {
                        Text("Select")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                    }
                }
                .accessibilityLabel(viewModel.isDeleteMode ? "Cancel selection" : "Select mindmaps")
            }
        }
    }
    
    // 6. Bottom delete button
    @ViewBuilder
    private var confirmDeleteButton: some View {
        if viewModel.isDeleteMode, !viewModel.selectedDeleteID.isEmpty {
            Button("Delete Mindmap", role: .destructive, action: { viewModel.deleteSelected() })
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
