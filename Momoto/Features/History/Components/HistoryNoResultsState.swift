//
//  HistoryNoResultsState.swift
//  MomotoMindmap
//

import SwiftUI

struct HistoryNoResultsState: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(.largeTitle, design: .rounded).weight(.light))
                .foregroundStyle(Theme.purple.opacity(0.5))
            
            Text("No results for \"\(searchText)\"")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }
}
