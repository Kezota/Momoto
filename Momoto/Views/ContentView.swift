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
    case mindmap
    case chatbot
    case history
}

// MARK: - AppState
class AppState: ObservableObject {
    @Published var path = NavigationPath()
}

// MARK: - AppColors
struct AppColors {
    static let pageBackground = Color(red: 0.94, green: 0.94, blue: 0.97)
    static let themePurple    = Color(red: 0.40, green: 0.30, blue: 0.90)
    static let themeOrange    = Color(red: 0.95, green: 0.65, blue: 0.15)
    static let themeRed       = Color(red: 0.88, green: 0.30, blue: 0.28)
    static let themeGreen     = Color(red: 0.28, green: 0.72, blue: 0.42)
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
                AppColors.pageBackground.ignoresSafeArea()
                VStack(spacing: 0) {
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
                                GridCard(
                                    color: AppColors.themePurple,
                                    iconName: "character.cursor.ibeam",
                                    title: "Paste Text"
                                ) { appState.path.append(AppRoute.paste) }

                                GridCard(
                                    color: AppColors.themeOrange,
                                    iconName: "doc.fill",
                                    title: "Upload PDF"
                                ) { appState.path.append(AppRoute.pdf) }

                                GridCard(
                                    color: AppColors.themeRed,
                                    iconName: "camera.viewfinder",
                                    title: "Scan with Camera"
                                ) { appState.path.append(AppRoute.scan) }

                                GridCard(
                                    color: AppColors.themeGreen,
                                    iconName: "arrow.triangle.branch",
                                    title: "Past Mindmaps"
                                ) { appState.path.append(AppRoute.history) }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .scan:       CameraView { capturedText in
                                    appState.path.append(AppRoute.processing)
                                }
                case .pdf:        UploadFileView { extractedText in
                                        appState.path.append(AppRoute.processing)
                                    }
                case .paste:      PasteTextView { submittedText in
                                        appState.path.append(AppRoute.processing)
                                    }
                case .processing: ProcessingView()
                case .mindmap:    MindMapView()
                case .chatbot:    EmptyView()
                case .history:    HistoryView(
                                        history: [],
                                        onTap: { item in
                                            // Navigate to mindmap or processing as needed
                                            appState.path.append(AppRoute.mindmap)
                                        },
                                        onDelete: { indexSet in
                                            // Handle deletion if needed
                                        }
                                    )
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
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
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    )

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(color)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HomeView().environmentObject(AppState())
}
