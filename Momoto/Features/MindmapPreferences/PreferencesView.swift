import SwiftUI

struct PreferencesView: View {

    @StateObject private var viewModel = MindmapPreferencesViewModel()
    @Binding var extractedText: String
    @State private var showPreview = false

    var onGenerate: (MindmapPreferences) -> Void

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        intro
                        
                        PreferenceCard(
                            icon: "point.3.filled.connected.trianglepath.dotted",
                            title: "Level of detail",
                            subtitle: "How deep the map goes.",
                            selection: $viewModel.detail
                        )
                        
                        PreferenceCard(
                            icon: "textformat.size",
                            title: "Reading level",
                            subtitle: "How simple the wording is.",
                            selection: $viewModel.complexity
                        )
                        
                        PreferenceCard(
                            icon: "globe",
                            title: "Language",
                            subtitle: "Output language.",
                            selection: $viewModel.language
                        )
                        
                        summaryCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                
                generateBar
            }
        }
        .navigationTitle("Personalize")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Preview") { showPreview = true }
            }
        }
        .sheet(isPresented: $showPreview) {
            ExtractedTextSheet(text: $extractedText)
        }
    }

    private var intro: some View {
        Text("Choose how your mindmap is built.")
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
    }

    /// Restates the three separate choices as one sentence, so the combined outcome is clear
    /// before committing to a generation that takes a while.
    private var summaryCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.purple)

            Text(summaryText)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.accentSoft)
        )
        .padding(.top, 4)
    }

    private var summaryText: String {
        let detail = viewModel.detail.label.lowercased()
        let complexity = viewModel.complexity.label.lowercased()
        let language = viewModel.language.label
        return "A \(detail) map in \(complexity) \(language), \(viewModel.detail.maxDepth) levels deep."
    }

    private var generateBar: some View {
        Button("Generate Mindmap") {
            viewModel.submit(onGenerate: onGenerate)
        }
        .buttonStyle(PrimaryButtonStyle(color: Theme.purple, isFullWidth: true))
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(
            Theme.background.ignoresSafeArea(edges: .bottom)
                .shadow(color: Theme.black.opacity(0.05), radius: 10, x: 0, y: -4)
        )
    }
}

#Preview {
    NavigationStack {
        PreferencesView(extractedText: .constant("Extracted text preview."), onGenerate: { _ in })
    }
}
