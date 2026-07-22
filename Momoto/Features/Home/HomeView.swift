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
    case recent = "Recent"
    
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
    @State private var isSearching = false
    @State private var searchText = ""
    
    var filteredMindmaps: [MindMap] {
        var list = mindmaps
        
        // Filter by selected tab
        switch selectedFilter {
        case .all:
            break
        case .favorite:
            list = list.filter { favoriteIDs.contains($0.id.uuidString) }
        case .recent:
            list = list.sorted { $0.createdAt > $1.createdAt }
        }
        
        // Filter by search query
        if !searchText.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.rawText.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sorting
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
    
    var favoriteMindmaps: [MindMap] {
        mindmaps.filter { favoriteIDs.contains($0.id.uuidString) }
    }
    
    var recentMindmaps: [MindMap] {
        mindmaps.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationStack(path: $appState.path) {
            ZStack(alignment: .bottom) {
                Theme.background.ignoresSafeArea()
                
                if isSearching {
                    searchViewContent
                } else {
                    mainDashboardContent
                }
                
                // Floating Bottom Search Bar & Create FAB (+) Button
                bottomBar
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isCreateSheetPresented) {
                CreateMindmapSheet(
                    onSelectOption: { route in
                        isCreateSheetPresented = false
                        appState.path.append(route)
                    }
                )
                .presentationDetents([.height(420)])
                .presentationCornerRadius(32)
                .presentationDragIndicator(.visible)
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
                headerView
                
                filterPillsView
                
                if selectedFilter == .all && layoutStyle == .grid && searchText.isEmpty {
                    dashboardOverviewSections
                } else {
                    if layoutStyle == .grid {
                        gridView(items: filteredMindmaps)
                    } else {
                        listView(items: filteredMindmaps)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Mindmaps")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            
            Spacer()
            
            Menu {
                Button(action: {}) {
                    Label("Select", systemImage: "checkmark.circle")
                }
                
                Divider()
                
                Button(action: {
                    withAnimation(.easeInOut) { layoutStyle = .grid }
                }) {
                    Label("Grid", systemImage: layoutStyle == .grid ? "checkmark" : "square.grid.2x2")
                }
                
                Button(action: {
                    withAnimation(.easeInOut) { layoutStyle = .list }
                }) {
                    Label("List", systemImage: layoutStyle == .list ? "checkmark" : "list.bullet")
                }
                
                Divider()
                
                Menu("Sort by Date") {
                    Button("Newest First") { sortOption = .dateDescending }
                    Button("Oldest First") { sortOption = .dateAscending }
                }
                
                Menu("Sort by Title") {
                    Button("A to Z") { sortOption = .titleAscending }
                    Button("Z to A") { sortOption = .titleDescending }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Filter Pills Bar
    private var filterPillsView: some View {
        HStack(spacing: 8) {
            ForEach(MindmapFilterTab.allCases) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = tab
                    }
                }) {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            selectedFilter == tab ? Theme.purple : Color.black.opacity(0.05)
                        )
                        .foregroundStyle(selectedFilter == tab ? Theme.white : Theme.textPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
    
    // MARK: - Dashboard Sections (Favorite & Recent)
    private var dashboardOverviewSections: some View {
        VStack(alignment: .leading, spacing: 28) {
            // Favorite Section
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Favorite")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button("See all") {
                        withAnimation { selectedFilter = .favorite }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.purple)
                }
                
                if favoriteMindmaps.isEmpty {
                    emptyPlaceholder(message: "No favorite mindmaps yet")
                } else {
                    gridView(items: Array(favoriteMindmaps.prefix(2)))
                }
            }
            
            // Recent Section
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Recent")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button("See all") {
                        withAnimation { selectedFilter = .recent }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.purple)
                }
                
                if recentMindmaps.isEmpty {
                    emptyPlaceholder(message: "No recent mindmaps")
                } else {
                    gridView(items: Array(recentMindmaps.prefix(4)))
                }
            }
        }
    }
    
    // MARK: - Grid Layout
    private func gridView(items: [MindMap]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            ForEach(items) { item in
                MindmapGridCard(
                    mindmap: item,
                    isFavorite: favoriteIDs.contains(item.id.uuidString),
                    onTap: { appState.path.append(AppRoute.mindmap(item)) },
                    onToggleFavorite: { toggleFavorite(for: item) },
                    onDelete: { deleteMindmap(item) }
                )
            }
        }
    }
    
    // MARK: - List Layout
    private func listView(items: [MindMap]) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(items) { item in
                MindmapListRow(
                    mindmap: item,
                    isFavorite: favoriteIDs.contains(item.id.uuidString),
                    onTap: { appState.path.append(AppRoute.mindmap(item)) },
                    onToggleFavorite: { toggleFavorite(for: item) },
                    onDelete: { deleteMindmap(item) }
                )
            }
        }
    }
    
    // MARK: - Search Mode Screen
    private var searchViewContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: {
                    withAnimation {
                        isSearching = false
                        searchText = ""
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.05))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Search Mindmap")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                
                Text("\(filteredMindmaps.count) results for \"\(searchText.isEmpty ? "All" : searchText)\" found")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 20)
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(filteredMindmaps) { item in
                        SearchResultRow(
                            mindmap: item,
                            onTap: { appState.path.append(AppRoute.mindmap(item)) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - Bottom Search & FAB Bar
    private var bottomBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                
                TextField("Search", text: $searchText, onEditingChanged: { editing in
                    if editing {
                        withAnimation { isSearching = true }
                    }
                })
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                
                Image(systemName: "mic.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            )
            
            Button(action: { isCreateSheetPresented = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Theme.purple)
                    .clipShape(Circle())
                    .shadow(color: Theme.purple.opacity(0.4), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
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
    
    private func emptyPlaceholder(message: String) -> some View {
        HStack {
            Spacer()
            Text(message)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .padding(.vertical, 24)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
        )
    }
}

// MARK: - Mindmap Card Component (Grid)
struct MindmapGridCard: View {
    let mindmap: MindMap
    let isFavorite: Bool
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "F3F4F8"))
                    .frame(height: 120)
                
                MiniMindmapGraphic()
                    .padding(12)
                
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color(hex: "F3A528"))
                        .clipShape(Circle())
                        .padding(8)
                }
            }
            .onTapGesture { onTap() }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mindmap.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(formattedDate(mindmap.createdAt))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer(minLength: 0)
                
                Menu {
                    Button(action: onToggleFavorite) {
                        Label(isFavorite ? "Unfavorite" : "Favorite", systemImage: isFavorite ? "star.slash" : "star")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(4)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Mini Mindmap Graphic Preview
struct MiniMindmapGraphic: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: w * 0.3, y: h * 0.5))
                    p.addLine(to: CGPoint(x: w * 0.6, y: h * 0.25))
                    p.move(to: CGPoint(x: w * 0.3, y: h * 0.5))
                    p.addLine(to: CGPoint(x: w * 0.6, y: h * 0.5))
                    p.move(to: CGPoint(x: w * 0.3, y: h * 0.5))
                    p.addLine(to: CGPoint(x: w * 0.6, y: h * 0.75))
                }
                .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.purple)
                    .frame(width: w * 0.35, height: h * 0.35)
                    .position(x: w * 0.22, y: h * 0.5)
                
                VStack(spacing: h * 0.08) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "46B76B"))
                        .frame(width: w * 0.32, height: h * 0.22)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "F3A528"))
                        .frame(width: w * 0.32, height: h * 0.22)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "FF4E6B"))
                        .frame(width: w * 0.32, height: h * 0.22)
                }
                .position(x: w * 0.72, y: h * 0.5)
            }
        }
    }
}

// MARK: - Mindmap List Row Component
struct MindmapListRow: View {
    let mindmap: MindMap
    let isFavorite: Bool
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: "F3F4F8"))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "brain")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.purple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mindmap.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text(formattedDate(mindmap.createdAt))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
                
                if isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "F3A528"))
                }
                
                Menu {
                    Button(action: onToggleFavorite) {
                        Label(isFavorite ? "Unfavorite" : "Favorite", systemImage: isFavorite ? "star.slash" : "star")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(8)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let mindmap: MindMap
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "F3F4F8"))
                            .frame(width: 36, height: 36)
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mindmap.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text(formattedDate(mindmap.createdAt))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Theme.textSecondary)
                }
                
                if !mindmap.rawText.isEmpty {
                    Text(mindmap.rawText)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                        .padding(10)
                        .background(Color(hex: "F8F9FC"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Create Mindmap Sheet (Bottom Sheet)
struct CreateMindmapSheet: View {
    let onSelectOption: (AppRoute) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Create new mindmap")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(Color.black.opacity(0.06))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 8)
            
            VStack(spacing: 12) {
                optionRow(
                    icon: "character.cursor.ibeam",
                    title: "Paste Text",
                    subtitle: "Type or paste any content",
                    route: .paste
                )
                
                optionRow(
                    icon: "doc.fill",
                    title: "Upload PDF",
                    subtitle: "Type or paste any content",
                    route: .pdf
                )
                
                optionRow(
                    icon: "camera.viewfinder",
                    title: "Scan with Camera",
                    subtitle: "Type or paste any content",
                    route: .scan
                )
                
                optionRow(
                    icon: "photo.fill",
                    title: "Use Photo",
                    subtitle: "Type or paste any content",
                    route: .photo
                )
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.white)
    }
    
    private func optionRow(icon: String, title: String, subtitle: String, route: AppRoute) -> some View {
        Button(action: { onSelectOption(route) }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.purple.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView().environmentObject(AppState())
}
