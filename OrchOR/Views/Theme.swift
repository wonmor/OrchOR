import SwiftUI

enum Theme {
    static let background = Color(red: 0.02, green: 0.04, blue: 0.09)
    static let backgroundTop = Color(red: 0.05, green: 0.10, blue: 0.20)
    static let teal = Color(red: 0.40, green: 0.89, blue: 0.78)
    static let violet = Color(red: 0.70, green: 0.50, blue: 1.0)
    static let amber = Color(red: 1.0, green: 0.72, blue: 0.30)
    static let rose = Color(red: 1.0, green: 0.45, blue: 0.55)
    static let card = Color.white.opacity(0.07)
    static let cardStroke = Color.white.opacity(0.10)
    static var gradient: LinearGradient {
        LinearGradient(colors: [backgroundTop, background], startPoint: .top, endPoint: .bottom)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(14)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.cardStroke, lineWidth: 1))
    }
}
extension View { func card() -> some View { modifier(CardModifier()) } }

struct SectionTitle: View {
    let text: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text).font(.headline)
            if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Readout: View {
    let label: String
    let value: String
    var color: Color = .primary
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.system(.subheadline, design: .monospaced).weight(.semibold)).foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LabeledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var format: (Double) -> String
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(label).font(.caption)
                Spacer()
                Text(format(value)).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }
}
