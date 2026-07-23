//
//  MomotoApp.swift
//  Momoto
//
//  Created by Kezia Meilany Tandapai on 05/05/26.
//

import SwiftUI

@main
struct MomotoApp: App {
    @StateObject private var appState = AppState()

    init() {
        // SwiftUI's `.segmented` picker ignores per-item foreground styling and `.tint`, so the
        // selected-segment colour has to be set through the underlying UIKit control.
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Theme.purple)
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor.white],
            for: .selected
        )
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.foregroundColor: UIColor(Theme.textPrimary)],
            for: .normal
        )
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}
