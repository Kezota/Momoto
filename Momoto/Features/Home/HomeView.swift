//
//  HomeView.swift
//  MomotoMindmap
//

import SwiftUI
import Combine

// MARK: - AppState
class AppState: ObservableObject {
    @Published var path = NavigationPath()
    @Published var pendingInputText = ""
    @Published var pendingPreferences: MindmapPreferences = .default
}

// MARK: - Filter & Layout Types
enum MindmapFilterTab: String, CaseIterable, Identifiable {
    case all = "All"
    case favorite = "Favorite"

    var id: String { rawValue }
}

enum LayoutStyle {
    case grid
    case list
}

enum SortOption {
    case dateDescending
    case dateAscending
    case titleAscending
    case titleDescending
}

// MARK: - HomeView
struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    @State private var mindmaps: [MindMap] = []
    @State private var favoriteIDs: Set<String> = []
    @State private var selectedFilter: MindmapFilterTab = .all
    @State private var layoutStyle: LayoutStyle = .grid
    @State private var sortOption: SortOption = .dateDescending

    @State private var isCreateSheetPresented = false
    @State private var searchText = ""
    @State private var pendingDeletion: MindMap?

    var filteredMindmaps: [MindMap] {
        var list = mindmaps

        if selectedFilter == .favorite {
            list = list.filter { favoriteIDs.contains($0.id.uuidString) }
        }

        if !searchText.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.rawText.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOption {
        case .dateDescending:
            list.sort { $0.createdAt > $1.createdAt }
        case .dateAscending:
            list.sort { $0.createdAt < $1.createdAt }
        case .titleAscending:
            list.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .titleDescending:
            list.sort { $0.title.localizedCompare($1.title) == .orderedDescending }
        }

        return list
    }

    var body: some View {
        NavigationStack(path: $appState.path) {
            mainDashboardContent
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Mindmaps")
            .navigationBarTitleDisplayMode(.large)
            // Native search + create live in the system toolbar rather than a hand-drawn
            // floating bar, so they pick up Liquid Glass, keyboard avoidance, the cancel
            // affordance, Dynamic Type and VoiceOver for free.
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    viewOptionsMenu
                }

                DefaultToolbarItem(kind: .search, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    Button("New Mindmap", systemImage: "plus") {
                        isCreateSheetPresented = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.purple)
                }
            }
            .sheet(isPresented: $isCreateSheetPresented) {
                CreateMindmapSheet(
                    onSelectOption: { route in
                        isCreateSheetPresented = false
                        appState.path.append(route)
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Delete \u{201C}\(pendingDeletion?.title ?? "")\u{201D}?",
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let pendingDeletion { deleteMindmap(pendingDeletion) }
                    pendingDeletion = nil
                }
                Button("Cancel", role: .cancel) { pendingDeletion = nil }
            } message: {
                Text("This mindmap will be permanently deleted.")
            }
            .onAppear {
                loadData()
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .scan:
                    CameraView(onTextCaptured: processInput)
                case .pdf:
                    UploadFileView(onTextExtracted: processInput)
                case .photo:
                    UploadPhotoView(onTextExtracted: processInput)
                case .paste:
                    PasteTextView(onSubmit: processInput)
                case .preferences:
                    PreferencesView(onGenerate: { prefs in
                        appState.pendingPreferences = prefs
                        appState.path.append(AppRoute.processing)
                    })
                case .processing:
                    ProcessingView()
                case .mindmap(let mindMap):
                    MindMapView(mindMap: mindMap)
                case .chatbot:
                    EmptyView()
                case .history:
                    HistoryView(
                        onTap: { appState.path.append(AppRoute.mindmap($0)) }
                    )
                }
            }
        }
    }

    // MARK: - Main Dashboard
    private var mainDashboardContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                filterPillsView

                if filteredMindmaps.isEmpty {
                    emptyState
                        .padding(.top, 40)
                } else if layoutStyle == .grid {
                    gridView(items: filteredMindmaps)
                } else {
                    listView(items: filteredMindmaps)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    // MARK: - View Options (native toolbar menu)
    private var viewOptionsMenu: some View {
        Menu {
            Picker("Layout", selection: $layoutStyle) {
                Label("Grid", systemImage: "square.grid.2x2").tag(LayoutStyle.grid)
                Label("List", systemImage: "list.bullet").tag(LayoutStyle.list)
            }
            .pickerStyle(.inline)

            Picker("Sort By", selection: $sortOption) {
                Label("Newest First", systemImage: "arrow.down").tag(SortOption.dateDescending)
                Label("Oldest First", systemImage: "arrow.up").tag(SortOption.dateAscending)
                Label("Title A–Z", systemImage: "textformat").tag(SortOption.titleAscending)
                Label("Title Z–A", systemImage: "textformat").tag(SortOption.titleDescending)
            }
            .pickerStyle(.inline)
        } label: {
            Label("View Options", systemImage: "ellipsis")
        }
    }

    // MARK: - Filter (native segmented control)
    private var filterPillsView: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(MindmapFilterTab.allCases) { tab in
                // Colour comes from `UISegmentedControl.appearance()` in MomotoApp — a
                // segmented Picker drops any styling applied to its items here.
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    // MARK: - Empty States
    @ViewBuilder
    private var emptyState: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if selectedFilter == .favorite {
            ContentUnavailableView(
                "No Favorites",
                systemImage: "star",
                description: Text("Mark a mindmap as favorite to find it quickly here.")
            )
        } else {
            ContentUnavailableView(
                "No Mindmaps Yet",
                systemImage: "brain",
                description: Text("Tap + to create your first mindmap from text, a PDF, a photo, or a scan.")
            )
        }
    }

    // MARK: - Grid Layout
    private func gridView(items: [MindMap]) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
            spacing: 16
        ) {
            ForEach(items) { item in
                MindmapGridCard(
                    mindmap: item,
                    isFavorite: favoriteIDs.contains(item.id.uuidString),
                    searchQuery: searchText,
                    onTap: { appState.path.append(AppRoute.mindmap(item)) },
                    onToggleFavorite: { toggleFavorite(for: item) },
                    onDelete: { pendingDeletion = item }
                )
            }
        }
    }

    // MARK: - List Layout
    private func listView(items: [MindMap]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(items) { item in
                MindmapListRow(
                    mindmap: item,
                    isFavorite: favoriteIDs.contains(item.id.uuidString),
                    searchQuery: searchText,
                    onTap: { appState.path.append(AppRoute.mindmap(item)) },
                    onToggleFavorite: { toggleFavorite(for: item) },
                    onDelete: { pendingDeletion = item }
                )

                if item.id != items.last?.id {
                    Divider().padding(.leading, 92)
                }
            }
        }
    }

    // MARK: - Helpers & Operations
    private func loadData() {
        mindmaps = HistoryService.shared.load()
        if let savedFavs = UserDefaults.standard.stringArray(forKey: "favorite_mindmap_ids") {
            favoriteIDs = Set(savedFavs)
        }
    }

    private func toggleFavorite(for mindmap: MindMap) {
        let key = mindmap.id.uuidString
        if favoriteIDs.contains(key) {
            favoriteIDs.remove(key)
        } else {
            favoriteIDs.insert(key)
        }
        UserDefaults.standard.set(Array(favoriteIDs), forKey: "favorite_mindmap_ids")
    }

    private func deleteMindmap(_ mindmap: MindMap) {
        HistoryService.shared.delete(id: mindmap.id)
        loadData()
    }

    private func processInput(_ text: String) {
        appState.pendingInputText = text
        appState.path.append(AppRoute.preferences)
    }
}

// MARK: - Shared row/card menu
private struct MindmapActionsMenu: View {
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Menu {
            Button(action: onToggleFavorite) {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "star.slash" : "star"
                )
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            // SF Symbols ships `ellipsis` horizontally; rotating is the safe way to get the
            // vertical variant used in the design without depending on a newer symbol name.
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More actions")
    }
}

private func relativeDate(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
}

/// Marks every case-insensitive occurrence of `query` inside `text` with a highlight, so search
/// results show *why* they matched. Returns the plain text unchanged when there is no query.
private func highlighting(_ text: String, query: String) -> AttributedString {
    var attributed = AttributedString(text)
    let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !needle.isEmpty else { return attributed }

    var searchRange = attributed.startIndex..<attributed.endIndex
    while let match = attributed[searchRange].range(of: needle, options: .caseInsensitive) {
        attributed[match].backgroundColor = Theme.yellow.opacity(0.45)
        attributed[match].foregroundColor = Theme.textPrimary

        guard match.upperBound < attributed.endIndex else { break }
        searchRange = match.upperBound..<attributed.endIndex
    }

    return attributed
}

// MARK: - Mindmap Card Component (Grid)
struct MindmapGridCard: View {
    let mindmap: MindMap
    let isFavorite: Bool
    var searchQuery: String = ""
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Preview
            ZStack(alignment: .topLeading) {
                Color.white

                MindmapThumbnail(root: mindmap.root)
                    .padding(10)

                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Theme.yellow))
                        .padding(8)
                }
            }
            .frame(height: 128)
            .clipped()

            // Info strip. The title wraps to two lines and gets a reserved minimum height so
            // long titles stay readable and every card in a grid row keeps the same height.
            HStack(alignment: .top, spacing: 4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(highlighting(mindmap.title, query: searchQuery))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(relativeDate(mindmap.createdAt))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                MindmapActionsMenu(
                    isFavorite: isFavorite,
                    onToggleFavorite: onToggleFavorite,
                    onDelete: onDelete
                )
            }
            .padding(.leading, 12)
            .padding(.trailing, 4)
            .padding(.vertical, 10)
            .background(Color(uiColor: .systemGray6))
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button(action: onToggleFavorite) {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "star.slash" : "star"
                )
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mindmap.title), \(relativeDate(mindmap.createdAt))")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Mindmap List Row Component
struct MindmapListRow: View {
    let mindmap: MindMap
    let isFavorite: Bool
    var searchQuery: String = ""
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white)

                MindmapThumbnail(root: mindmap.root)
                    .padding(6)

                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Theme.yellow))
                        .padding(4)
                }
            }
            .frame(width: 78, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(highlighting(mindmap.title, query: searchQuery))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(relativeDate(mindmap.createdAt))
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            MindmapActionsMenu(
                isFavorite: isFavorite,
                onToggleFavorite: onToggleFavorite,
                onDelete: onDelete
            )
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button(action: onToggleFavorite) {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "star.slash" : "star"
                )
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mindmap.title), \(relativeDate(mindmap.createdAt))")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Create Mindmap Sheet
/// A plain, edge-to-edge `List` inside a `NavigationStack` — the system pattern for "pick one of
/// these actions", so it brings platform row heights, press states, separators, Dynamic Type and
/// VoiceOver ordering that a hand-built button stack doesn't.
struct CreateMindmapSheet: View {
    let onSelectOption: (AppRoute) -> Void
    @Environment(\.dismiss) private var dismiss

    private struct Option: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
        let route: AppRoute
    }

    private let options: [Option] = [
        Option(
            icon: "character.cursor.ibeam",
            title: "Paste Text",
            subtitle: "Type or paste any content",
            route: .paste
        ),
        Option(
            icon: "doc.fill",
            title: "Upload PDF",
            subtitle: "Turn a document into a mindmap",
            route: .pdf
        ),
        Option(
            icon: "camera.viewfinder",
            title: "Scan with Camera",
            subtitle: "Capture text from a page",
            route: .scan
        ),
        Option(
            icon: "photo.fill",
            title: "Use Photo",
            subtitle: "Pick an image from your library",
            route: .photo
        )
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    Button {
                        onSelectOption(option.route)
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Theme.accentSoft)
                                    .frame(width: 48, height: 48)

                                Image(systemName: option.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Theme.purple)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.title)
                                    .font(.system(.body, design: .rounded).weight(.bold))
                                    .foregroundStyle(Theme.textPrimary)

                                // Explicit colour, not the hierarchical `.secondary`: inside a
                                // List row Button the button tint is the base style, so `.secondary`
                                // resolves to a faded *accent blue* rather than a neutral grey.
                                Text(option.subtitle)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                    // Stops the row inheriting the accent tint on its whole label.
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                    // Divider spans the full width rather than starting after the icon.
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    // Separators sit *between* rows only — nothing trailing the last one.
                    .listRowSeparator(index == options.count - 1 ? .hidden : .visible, edges: .bottom)
                }
            }
            // `.plain` + explicit row insets keeps the rows flush with the sheet instead of the
            // floating inset card `.insetGrouped` draws.
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationTitle("Create new mindmap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    HomeView().environmentObject(AppState())
}
