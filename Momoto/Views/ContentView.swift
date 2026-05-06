//
//  ContentView.swift
//  MomotoMindmap
//

import SwiftUI
import Combine

// MARK: - Route
enum AppRoute: Hashable {
    case scan
    case pdf
    case paste
    case processing
    case mindmap(MindMap)
    case chatbot
    case history
}

// MARK: - AppState
class AppState: ObservableObject {
    @Published var path = NavigationPath()
    @Published var pendingInputText = ""
}

typealias ContentView = HomeView

// MARK: - HomeView
struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack(path: $appState.path) {
            ZStack {
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
                            GridCard(color: Theme.cardPaste, iconName: "character.cursor.ibeam", title: "Paste Text") {
                                appState.path.append(AppRoute.paste)
                            }
                            GridCard(color: Theme.cardPDF, iconName: "doc.fill", title: "Upload PDF") {
                                appState.path.append(AppRoute.pdf)
                            }
                            GridCard(color: Theme.cardScan, iconName: "camera.viewfinder", title: "Scan with Camera") {
                                appState.path.append(AppRoute.scan)
                            }
                            GridCard(color: Theme.cardHistory, iconName: "arrow.triangle.branch", title: "Past Mindmaps") {
                                appState.path.append(AppRoute.history)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .scan:
                    CameraView(onTextCaptured: processInput)
                case .pdf:
                    UploadFileView(onTextExtracted: processInput)
                case .paste:
                    PasteTextView(onSubmit: processInput)
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
        appState.path.append(AppRoute.processing)
    }
}

// MARK: - GridCard
struct GridCard: View {
    let color: Color
    let iconName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                Spacer()
                
                // Icon box
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.white.opacity(0.25))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(.largeTitle, design: .rounded).weight(.medium))
                            .foregroundColor(Theme.white)
                    )

                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(Theme.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(RoundedRectangle(cornerRadius: 24).fill(color))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView().environmentObject(AppState())
}
