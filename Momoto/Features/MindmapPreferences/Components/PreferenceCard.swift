import SwiftUI

struct PreferenceCard<Option: PreferenceOption>: View {

    let icon: String
    let title: String
    /// What this setting controls, in one line — shown once under the title.
    var subtitle: String = ""
    @Binding var selection: Option

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.purple)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.accentSoft)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.textPrimary)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                ForEach(Array(Option.allCases)) { option in
                    pill(option)
                }
            }

            // Live explanation of the current choice, so the difference between options is
            // legible up front instead of something you discover after generating.
            if !selection.caption.isEmpty {
                Text(selection.caption)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity)
                    .id(selection)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Theme.stroke, lineWidth: 1)
                )
                .shadow(color: Theme.black.opacity(0.04), radius: 12, x: 0, y: 6)
        )
    }

    private func pill(_ option: Option) -> some View {
        let isSelected = option == selection
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { selection = option }
        } label: {
            Text(option.label)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(isSelected ? Theme.white : Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Capsule().fill(isSelected ? Theme.purple : Theme.background))
                .overlay(Capsule().stroke(isSelected ? Color.clear : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    enum PreviewLayoutOption: String, PreferenceOption {
        case low, medium, high

        var id: String { rawValue }
        var label: String {
            switch self {
            case .low: return "Concise"
            case .medium: return "Balanced"
            case .high: return "Detailed"
            }
        }
        var caption: String {
            switch self {
            case .low: return "Main ideas only. 2 levels deep."
            case .medium: return "Key ideas plus support. 3 levels deep."
            case .high: return "Full detail. 4 levels deep."
            }
        }
    }

    return VStack(spacing: 20) {
        PreferenceCard(
            icon: "slider.horizontal.3",
            title: "Level of detail",
            subtitle: "How deep the map goes.",
            selection: .constant(PreviewLayoutOption.medium)
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
}
