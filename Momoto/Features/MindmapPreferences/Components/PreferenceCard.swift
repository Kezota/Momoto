import SwiftUI

struct PreferenceCard<Option: PreferenceOption>: View {
    
    let icon: String
    let title: String
    @Binding var selection: Option
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .frame(width: 60, height: 60)
                    .background(Theme.accentSoft)
                    
                
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            HStack(spacing: 8) {
                ForEach(Array(Option.allCases)) { option in
                    pill(option)
                }
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
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Capsule().fill(isSelected ? Theme.purple : Theme.background))
                .overlay(Capsule().stroke(isSelected ? Color.clear : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    // 1. A quick dummy enum that follows your PreferenceOption contract
    enum PreviewLayoutOption: String, PreferenceOption {
        case low, medium, high
        
        var id: String { rawValue }
        var label: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
    }
    
    // 2. Render the card inside a clean container
    return VStack(spacing: 20) {
        PreferenceCard(
            icon: "slider.horizontal.3",
            title: "Detail Level (Preview)",
            selection: .constant(PreviewLayoutOption.medium) // Locks it on Medium
        )
        
        PreferenceCard(
            icon: "textformat.size",
            title: "Complexity Level (Preview)",
            selection: .constant(PreviewLayoutOption.high) // Locks it on High
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background) // Uses your custom background token
}
