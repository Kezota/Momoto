//
//  HistoryEmptyState.swift
//  MomotoMindmap
//

import SwiftUI

struct HistoryEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain")
                .font(.system(.largeTitle, design: .rounded).weight(.light))
                .foregroundStyle(Theme.purple)
            
            Text("No mindmap available")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 248)
    }
}
