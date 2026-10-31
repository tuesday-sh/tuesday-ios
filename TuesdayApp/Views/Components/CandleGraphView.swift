import SwiftUI

/// Ported from SureThingNet's `CandleGraph` widget (`candle_graph.dart`)
public struct CandleGraphView: View {
    public let score: Double

    public init(score: Double) {
        self.score = score
    }

    private var clampedScore: Double {
        min(100.0, max(0.0, score))
    }

    private var scoreColor: Color {
        if clampedScore < 40.0 {
            return TuesdayTheme.criticalRed
        } else if clampedScore < 75.0 {
            return TuesdayTheme.warningAmber
        } else {
            return TuesdayTheme.healthyGreen
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Package Health Score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(white: 0.70))
                Spacer()
                Text("\(Int(clampedScore.rounded()))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(scoreColor)
                    .shadow(color: scoreColor.opacity(0.45), radius: 6)
            }

            GeometryReader { geo in
                let width = max(12.0, geo.size.width)
                let markerX = (clampedScore / 100.0) * (width - 6.0)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    TuesdayTheme.criticalRed,
                                    TuesdayTheme.warningAmber,
                                    TuesdayTheme.healthyGreen
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: 6, height: 16)
                        .shadow(color: scoreColor.opacity(0.85), radius: 6)
                        .offset(x: markerX)
                        .animation(.spring(response: 0.5, dampingFraction: 0.72), value: clampedScore)
                }
            }
            .frame(height: 16)
        }
    }
}
