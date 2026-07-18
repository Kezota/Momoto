import SwiftUI

struct PreferencesView: View {

    @StateObject private var viewModel = MindmapPreferencesViewModel()

    var onGenerate: (MindmapPreferences) -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        header

                        PreferenceCard(icon: "pencil.line", title: "Node Detail",
                                       selection: $viewModel.detail)
                        PreferenceCard(icon: "textformat.size", title: "Summary Complexity",
                                       selection: $viewModel.complexity)
                        PreferenceCard(icon: "globe", title: "Language",
                                       selection: $viewModel.language)
                    }
                    .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 24)
                }
                generateBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Personalize mindmap!")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Choose your preferences!")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12).padding(.bottom, 4)
    }

    private var generateBar: some View {
        Button("Generate Mindmap") {
            viewModel.submit(onGenerate: onGenerate)
        }
        .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 24)
        .background(
            Theme.background.ignoresSafeArea(edges: .bottom)
                .shadow(color: Theme.black.opacity(0.05), radius: 10, x: 0, y: -4)
        )
    }
}

#Preview {
      NavigationStack {
          PreferencesView(onGenerate: { _ in })
      }
  }
