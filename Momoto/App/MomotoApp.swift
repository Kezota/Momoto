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

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}
