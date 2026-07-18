//
//  HomeCard.swift
//  MomotoMindmap
//

import SwiftUI

struct HomeCard: View {
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
