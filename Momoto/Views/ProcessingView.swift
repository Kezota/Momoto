//
//  ProcessingView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI
import Combine

struct ProcessingView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProcessingViewModel()
    
    @State private var isAnimating = false
    @State private var textIndex = 0
    
    private let loadingTexts = [
        "Reading your content",
        "Identifying key concept",
        "Building node hierarchy",
        "Finalising Mindmap"
    ]
    
    // Definisikan warna langsung dengan nilai RGB (0-1)
    let themePurple = Color(red: 0.47, green: 0.38, blue: 1.0)
    let inactiveGray = Color(red: 0.92, green: 0.92, blue: 0.95) // Abu-abu terang untuk dot yang belum aktif
    
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color(white: 0.98).ignoresSafeArea()
            
            switch viewModel.state {
            case .loading:
                loadingBody
                
            case .success(let mindMap):
                Color.clear // keeps the screen blank while the navigation push animates.
                    .onAppear {
                        appState.path.append(AppRoute.mindmap(mindMap))
                    }
                
            case .failure(let message):
                errorBody(message: message)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            // Run the AI call the moment this view appears.
            await viewModel.generate(
                from: appState.pendingInputText,
                source: "App"
            )
        }
    }
    
    
    private var loadingBody: some View {
        VStack(spacing: 24) {
            
            // Progress Indicator & Icon
            ZStack {
                Circle()
                    .stroke(themePurple.opacity(0.1), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.4)
                    .stroke(themePurple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            isAnimating = true
                        }
                    }
                
                Image(systemName: "sparkles")
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundColor(themePurple)
            }
            .padding(.bottom, 8)
            
            // Dynamic Text Labels
            VStack(spacing: 8) {
                Text("Generating Mindmap")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                
                Text(loadingTexts[textIndex])
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                    .id(textIndex)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.5), value: textIndex)
            }
            .onReceive(timer) { _ in
                if textIndex < loadingTexts.count - 1 {
                    textIndex += 1
                }
            }
            
            // Step Indicator (Menggunakan variabel warna langsung)
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Capsule()
                        .frame(width: index <= textIndex ? 35 : 12, height: 8)
                        .foregroundColor(index <= textIndex ? themePurple : inactiveGray)
                        .animation(.spring(), value: textIndex)
                }
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.98))
    }
    private func errorBody(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(.largeTitle, design: .rounded))
                .foregroundColor(.orange)
            Text("Something went wrong")
                .font(.system(.title3, design: .rounded).weight(.bold))
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") {
                Task {
                    await viewModel.generate(
                        from: appState.pendingInputText,
                        source: "App"
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
    }
}

#Preview {
    ProcessingView()
}
