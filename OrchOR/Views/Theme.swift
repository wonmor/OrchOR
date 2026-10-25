import SwiftUI

/// Dark Bauhaus design system: ink fields, off-white type, a strict red / yellow / blue palette used as
/// flat colour fields and thick rules, Futura display type, square corners, 2 pt rules. No gradients,
/// glass or soft shadows, and no geometric shapes as icons or ornaments: glyphs are SF Symbols line glyphs.
enum Theme {
    // Fields
    static let ink = Color(hex: 0x0E0E0E)          // page
    static let surface = Color(hex: 0x181818)      // panels
    static let raised = Color(hex: 0x242424)       // inactive control segments
    static let rule = Color(hex: 0x3A3A3A)         // 2 pt panel borders, gridlines
    // Type (contrast on surface: paper 15.3:1, muted 8.4:1)
    static let paper = Color(hex: 0xF2EEE6)
    static let muted = Color(hex: 0xB8B2A7)
    // Bauhaus primaries, tuned for dark. Use as fields, bars and rules.
    static let red = Color(hex: 0xE63B2E)
    static let yellow = Color(hex: 0xF2B705)
    static let blue = Color(hex: 0x2F6BFF)
    // Text-safe variants of red and blue for small type on dark (≥ 5.7:1 on surface).
    static let redText = Color(hex: 0xFF5A4D)
    static let blueText = Color(hex: 0x6E95FF)

    static let ruleWidth: CGFloat = 2
    static let barHeight: CGFloat = 6
    static let corner: CGFloat = 0
    /// Content width cap on iPad so lines stay readable on the hard grid.
    static let maxContentWidth: CGFloat = 1180

    /// Uppercase for tracked labels, leaving maths symbols and units-sensitive Greek alone (τ, ħ, µ, ∫).
    static func caps(_ s: String) -> String {
        s.map { "τħµ∫".contains($0) ? String($0) : $0.uppercased() }.joined()
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

/// Futura is the geometric grotesk of the period; all sizes scale with Dynamic Type.
enum BFont {
    static func display(_ size: CGFloat = 46, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom("Futura-Bold", size: size, relativeTo: style)
    }
    static func heading(_ size: CGFloat = 21, relativeTo style: Font.TextStyle = .title3) -> Font {
        .custom("Futura-Bold", size: size, relativeTo: style)
    }
    static func label(_ size: CGFloat = 12, relativeTo style: Font.TextStyle = .caption) -> Font {
        .custom("Futura-Medium", size: size, relativeTo: style)
    }
    static func number(_ style: Font.TextStyle = .title3) -> Font {
        .system(style, design: .monospaced).weight(.semibold)
    }
}

/// Uppercase, tightly tracked label.
struct TrackedText: View {
    let text: String
    var color: Color = Theme.muted
    var size: CGFloat = 12
    init(_ text: String, color: Color = Theme.muted, size: CGFloat = 12) {
        self.text = text; self.color = color; self.size = size
    }
    var body: some View {
        Text(Theme.caps(text))
            .font(BFont.label(size))
            .tracking(1.6)
            .foregroundStyle(color)
    }
}

// MARK: - Panels

/// Flat surface, square corners, 2 pt border, optional thick accent bar across the top.
struct PanelModifier: ViewModifier {
    var accent: Color?
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .padding(.top, accent == nil ? 0 : Theme.barHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .overlay(alignment: .top) {
                if let accent { accent.frame(height: Theme.barHeight) }
            }
            .overlay(Rectangle().strokeBorder(Theme.rule, lineWidth: Theme.ruleWidth))
    }
}

extension View {
    func panel(accent: Color? = nil, padding: CGFloat = 16) -> some View {
        modifier(PanelModifier(accent: accent, padding: padding))
    }

    /// Standard page frame: ink field edge to edge, content capped and centred on the grid.
    func pageFrame() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: Theme.maxContentWidth)
            .frame(maxWidth: .infinity)
    }
}

/// A full-width horizontal rule.
struct HRule: View {
    var color: Color = Theme.rule
    var height: CGFloat = Theme.ruleWidth
    var body: some View { color.frame(height: height).accessibilityHidden(true) }
}

// MARK: - Headers

/// Big display heading over a thick accent rule, with an index and tracked kicker above it.
struct ScreenHeader<Trailing: View>: View {
    let index: String
    let kicker: String
    let title: String
    let accent: Color
    @ViewBuilder var trailing: () -> Trailing

    init(index: String, kicker: String, title: String, accent: Color,
         @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.index = index; self.kicker = kicker; self.title = title; self.accent = accent; self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                TrackedText("\(index)  |  \(kicker)")
                Spacer(minLength: 8)
                trailing()
            }
            Text(title)
                .font(BFont.display())
                .foregroundStyle(Theme.paper)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 4)
            accent.frame(height: Theme.barHeight + 4).accessibilityHidden(true)
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

struct SectionTitle: View {
    let text: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text).font(BFont.heading()).foregroundStyle(Theme.paper)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle).font(.footnote).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Readouts

struct Readout: View {
    let label: String
    let value: String
    var color: Color = Theme.paper
    var style: Font.TextStyle = .title3
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TrackedText(label, size: 11)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(value)
                .font(BFont.number(style))
                .foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// A row of readouts on the grid that becomes a single column at accessibility text sizes.
struct ReadoutRow<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dts
    @ViewBuilder var content: Content
    var body: some View {
        let layout = dts.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        layout { content }
    }
}

// MARK: - Controls

/// A fader: 2 pt track rule, a thick accent fill and an off-white vertical handle bar.
struct BauhausSlider: View {
    @Environment(\.dynamicTypeSize) private var dts
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var accent: Color = Theme.yellow
    var format: (Double) -> String

    private var fraction: Double {
        let f = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return min(max(f, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            let layout = dts.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
            layout {
                TrackedText(label)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)
                Text(format(value))
                    .font(.system(.footnote, design: .monospaced).weight(.semibold))
                    .foregroundStyle(Theme.paper)
                    .fixedSize()
            }
            GeometryReader { geo in
                let w = geo.size.width
                let x = w * fraction
                ZStack(alignment: .leading) {
                    Theme.rule.frame(height: Theme.ruleWidth)
                    accent.frame(width: x, height: Theme.barHeight)
                    Theme.paper.frame(width: 6, height: 28)
                        .offset(x: min(max(0, x - 3), w - 6))
                }
                .frame(width: w, height: geo.size.height)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                    let f = min(max(g.location.x / max(w, 1), 0), 1)
                    value = range.lowerBound + f * (range.upperBound - range.lowerBound)
                })
            }
            .frame(height: 32)
        }
        .accessibilityRepresentation {
            Slider(value: $value, in: range) { Text(label) }
                .accessibilityValue(format(value))
        }
    }
}

/// Two-segment OFF / ON switch with a flat colour field for the active side.
struct BauhausToggleStyle: ToggleStyle {
    var accent: Color = Theme.red
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(alignment: .center, spacing: 12) {
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 0) {
                    segment("Off", active: !configuration.isOn, field: Theme.paper)
                    segment("On", active: configuration.isOn, field: accent)
                }
                .overlay(Rectangle().strokeBorder(Theme.paper, lineWidth: Theme.ruleWidth))
                .fixedSize()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "On" : "Off")
    }

    private func segment(_ t: String, active: Bool, field: Color) -> some View {
        Text(Theme.caps(t))
            .font(BFont.label(12))
            .tracking(1.6)
            .foregroundStyle(active ? Theme.ink : Theme.muted)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(active ? field : Theme.raised)
    }
}

struct BauhausButtonStyle: ButtonStyle {
    enum Kind { case filled(Color), outline(Color) }
    var kind: Kind
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        let color: Color
        let filled: Bool
        switch kind {
        case .filled(let c): color = c; filled = true
        case .outline(let c): color = c; filled = false
        }
        return configuration.label
            .font(BFont.label(compact ? 12 : 14, relativeTo: compact ? .caption : .subheadline))
            .tracking(1.4)
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(filled ? Theme.ink : color)
            .padding(.horizontal, compact ? 10 : 18)
            .padding(.vertical, compact ? 8 : 12)
            .background(filled ? color : Color.clear)
            .overlay(Rectangle().strokeBorder(color, lineWidth: Theme.ruleWidth))
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == BauhausButtonStyle {
    static func bauhaus(_ kind: BauhausButtonStyle.Kind, compact: Bool = false) -> BauhausButtonStyle {
        BauhausButtonStyle(kind: kind, compact: compact)
    }
}

/// Legend / key row: a line glyph tinted in the series colour, then a tracked label. No swatches or dots.
struct KeyRow: View {
    let glyph: String
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: glyph)
                .font(.system(.footnote).weight(.semibold))
                .foregroundStyle(color)
                .frame(minWidth: 18)
                .accessibilityHidden(true)
            TrackedText(text, color: Theme.paper, size: 11)
        }
    }
}

/// The real app icon, used wherever a brand mark appears.
struct BrandMark: View {
    var size: CGFloat = 56
    var body: some View {
        Image("BrandMark")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .accessibilityLabel("Orch-OR app icon")
    }
}
