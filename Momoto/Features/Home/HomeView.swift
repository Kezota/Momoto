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

// MARK: - HomeView
struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack(path: $appState.path) {
            ZStack(alignment: .topTrailing) {
                Theme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 36) {
                        // Logo
                        Image("MOMOTOLOGO")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 350)
                            .padding(.top, 70)
                            .padding(.bottom, 40)
                        
                        // 2x2 Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            HomeCard(color: Theme.cardPaste, iconName: "character.cursor.ibeam", title: "Paste Text") {
                                appState.path.append(AppRoute.paste)
                            }
                            HomeCard(color: Theme.cardPDF, iconName: "doc.fill", title: "Upload PDF") {
                                appState.path.append(AppRoute.pdf)
                            }
                            HomeCard(color: Theme.cardScan, iconName: "camera.viewfinder", title: "Scan with Camera") {
                                appState.path.append(AppRoute.scan)
                            }
                            HomeCard(color: Theme.cardHistory, iconName: "photo.fill", title: "Use Photo") {
                                appState.path.append(AppRoute.photo)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
                
                Button(action: { appState.path.append(AppRoute.history) }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.purple)
                        .padding(14)
                        .background(Theme.white)
                        .clipShape(Circle())
                        .shadow(color: Theme.black.opacity(0.08), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.top, 16)
            }
            .navigationBarHidden(true)
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
        .ignoresSafeArea()
    }
    
    // Helper to handle text extraction routes cleanly
    private func processInput(_ text: String) {
        appState.pendingInputText = text
        appState.path.append(AppRoute.preferences)
    }
}

#Preview {
    HomeView().environmentObject(AppState())
}
