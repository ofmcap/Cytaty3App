import SwiftUI

public struct LanguageChip: View {
    public let lang: LanguagePreference
    public let tap: () -> Void

    public init(lang: LanguagePreference, tap: @escaping () -> Void) {
        self.lang = lang
        self.tap = tap
    }

    public var body: some View {
        Button(action: tap) {
            Text(lang.displayCode)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(.thinMaterial))
        }
        .accessibilityLabel(Text("LANGUAGE_CHIP_LABEL %@".replacingOccurrences(of: "%@", with: lang.displayCode)))
        .accessibilityHint(Text("LANGUAGE_CHIP_HINT"))
    }
}
