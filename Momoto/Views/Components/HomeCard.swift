//
//  HomeCard.swift
//  MomotoMindmap
//

import SwiftUI

struct HomeCard: View {
    let color: Color
    let iconName: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon box
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(0.25))
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(color)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.88))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(color)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
