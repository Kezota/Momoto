//
//  ProcessingView.swift
//  MomotoMindmap
//
//  Created by Kezia Meilany Tandapai on 01/05/26.
//

import SwiftUI
import Combine

struct ProcessingView: View {
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
                    .font(.system(size: 30))
                    .foregroundColor(themePurple)
            }
            .padding(.bottom, 8)
            
            // Dynamic Text Labels
            VStack(spacing: 8) {
                Text("Generating Mindmap")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text(loadingTexts[textIndex])
                    .font(.system(size: 16))
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
}

#Preview {
    ProcessingView()
}
