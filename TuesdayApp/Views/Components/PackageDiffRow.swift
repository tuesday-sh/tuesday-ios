import SwiftUI

public struct PackageDiffRow: View {
    public let update: PackageUpdate

    public init(update: PackageUpdate) {
        self.update = update
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: update.isSecurityCritical ? "exclamationmark.shield.fill" : "shippingbox.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(update.isSecurityCritical ? TuesdayTheme.criticalRed : TuesdayTheme.warningAmber)

                Text(update.name)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if update.isSecurityCritical {
                    Text("SECURITY")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(TuesdayTheme.criticalRed)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(TuesdayTheme.criticalRed.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Spacer(minLength: 6)

                Text("\(update.currentVersion) → \(update.availableVersion)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(update.isSecurityCritical ? TuesdayTheme.criticalRed : TuesdayTheme.warningAmber)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if let note = update.advisoryNote, !note.isEmpty {
                Text(note)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.65))
                    .padding(.leading, 20)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.black.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
