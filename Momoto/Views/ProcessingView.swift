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
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            switch viewModel.state {
            case .loading:
                loadingBody
                
            case .success(let mindMap):
                Color.clear.onAppear { appState.path.append(AppRoute.mindmap(mindMap)) }
                
            case .failure(let message):
                errorBody(message: message)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.generate(from: appState.pendingInputText, source: "App") }
    }
    
    
    private var loadingBody: some View {
        VStack(spacing: 24) {
            
            // Progress Indicator & Icon
            ZStack {
                Circle()
                    .stroke(Theme.purple.opacity(0.12), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.4)
                    .stroke(Theme.purple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .onAppear { withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) { isAnimating = true } }
                
                Image(systemName: "sparkles")
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundColor(Theme.purple)
            }
            .padding(.bottom, 8)
            
            // Dynamic Text Labels
            VStack(spacing: 8) {
                Text("Generating Mindmap")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                
                Text(viewModel.currentLoadingText)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .id(viewModel.textIndex)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.textIndex)
            }
            
            // Step Indicator
            HStack(spacing: 8) {
                ForEach(0..<2) { index in
                    Capsule()
                        .frame(width: index <= viewModel.textIndex ? 35 : 12, height: 8)
                        .foregroundColor(index <= viewModel.textIndex ? Theme.purple : Theme.stroke)
                        .animation(.spring(), value: viewModel.textIndex)
                }
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorBody(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(.largeTitle, design: .rounded))
                .foregroundColor(Theme.yellow)
            Text("Something went wrong")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Try Again") { Task { await viewModel.generate(from: appState.pendingInputText, source: "App") } }
            .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: false))
        }
        .padding()
    }
}

#Preview {
    ProcessingView()
}
