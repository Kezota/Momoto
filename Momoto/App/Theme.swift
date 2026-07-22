//
//  Theme.swift
//  Momoto
//

import SwiftUI

// MARK: - Theme

enum Theme {

    // MARK: Brand colours
    // ──────────────────────────────────────────

    static let purple  = Color(hex: "634CE6")
    static let red     = Color(hex: "FF4E6B")
    static let green   = Color(hex: "46B76B")
    static let yellow  = Color(hex: "F3A528")
    static let teal    = Color(hex: "2BB7A5")
    static let blue    = Color(hex: "4E9EFF")

    // MARK: Neutral / text
    // ──────────────────────────────────────────

    static let black   = Color(hex: "080808")
    static let white   = Color(hex: "FAFAFA")
    static let textSecondary = Color(hex: "9B9B9B")

    // MARK: Surfaces
    // ──────────────────────────────────────────

    static let background = Color(hex: "F5F5FE")
    static let stroke = Color(hex: "EBEBEB")

    // MARK: Semantic / role-based aliases
    // ──────────────────────────────────────────

    static let textPrimary = black
    static let accent = purple
    static let accentSoft = purple.opacity(0.12)
    static let greenSoft = green.opacity(0.12)

    // MARK: Per-card colours (HomeView grid)
    // ──────────────────────────────────────────

    static let cardPaste  = purple
    static let cardPDF    = yellow
    static let cardScan   = red
    static let cardHistory = green

    // MARK: Dark surface (used in CameraView)
    // ──────────────────────────────────────────

    static let darkCard = Color(hex: "080808").opacity(0.92)
}

// MARK: - Color hex initialiser

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
