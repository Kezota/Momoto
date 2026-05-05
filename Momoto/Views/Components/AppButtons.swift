//
//  AppButtons.swift
//  MomotoMindmap
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.purple
    var isFullWidth: Bool = true
    
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.white)
            .padding(.horizontal, isFullWidth ? 16 : 24)
            .padding(.vertical, 16)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(Capsule().fill(color))
            .shadow(color: isEnabled ? color.opacity(0.35) : .clear, radius: 8, x: 0, y: 4)
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.55)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = Theme.purple
    
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Capsule().fill(color.opacity(0.12)))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.55)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}
