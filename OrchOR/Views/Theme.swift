import SwiftUI

/// The Bauhaus design language shared with John's other apps (Title Capitalizr, OrchPCB): white ground,
/// black ink, Jost geometric type, thick black rules, square edges, and the three primaries as flat fields
/// with fixed meanings in this app:
///
/// - blue: what you control (buttons, the selected tab, slider fills),
/// - yellow: coherent superposition,
/// - red: objective reduction, and decoherence that destroys superposition.
///
/// Classical tubulin states are black (A) and grey (B). No gradients, shadows or rounded corners; every
/// icon is an SF Symbol, never a decorative shape.
enum Theme {
    // Ground and ink
    static let ground = Color.white
    static let ink = Color.black
    /// #3C3C3C, 10.4:1 on white.
    static let inkSecondary = Color(hex: 0x3C3C3C)
    /// #F2F2F2 quiet field.
    static let soft = Color(hex: 0xF2F2F2)
    /// #CFCFCF chart gridlines and hairlines.
    static let hairline = Color(hex: 0xCFCFCF)

    // Primaries
    /// #0F3FA8, 9.1:1 on white; white text on it 9.1:1.
    static let blue = Color(hex: 0x0F3FA8)
    /// #F2C230, always with black ink on it (12.6:1).
    static let yellow = Color(hex: 0xF2C230)
    /// #D62828 fill, with white or black bold labels.
    static let red = Color(hex: 0xD62828)
    /// #A61B1B for red text on white (7.6:1).
    static let redInk = Color(hex: 0xA61B1B)

    // Tubulin states
    static let stateA = Color.black
    /// #8A8A8A, the second classical conformation.
    static let stateB = Color(hex: 0x8A8A8A)

    // Rules
    static let thin: CGFloat = 1
    static let rule: CGFloat = 2
    static let thick: CGFloat = 4
    static let heavy: CGFloat = 8

    static let tapTarget: CGFloat = 44
    /// Content width cap on iPad so lines stay readable on the grid.
    static let maxContentWidth: CGFloat = 1180

    /// Uppercase for tracked labels, leaving maths symbols and units-sensitive Greek alone (τ, ħ, µ, ∫).
    static func caps(_ s: String) -> String {
        s.map { "τħµ∫".contains($0) ? String($0) : $0.uppercased() }.joined()
    }

    /// Ink that reads on a given primary field.
    static func onField(_ c: Color) -> Color { c == yellow || c == ground || c == soft ? ink : ground }
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

/// Jost, a geometric sans in the Futura tradition (SIL Open Font License), bundled as a variable font.
/// Every size scales with Dynamic Type.
enum BFont {
    static let family = "Jost"
    static func jost(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(family, size: size, relativeTo: style).weight(weight)
    }
    static func display(_ size: CGFloat = 48, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        jost(size, .bold, relativeTo: style)
    }
    static func heading(_ size: CGFloat = 22, relativeTo style: Font.TextStyle = .title3) -> Font {
        jost(size, .bold, relativeTo: style)
    }
    static func label(_ size: CGFloat = 12, relativeTo style: Font.TextStyle = .caption) -> Font {
        jost(size, .semibold, relativeTo: style)
    }
    static let body = jost(16, relativeTo: .body)
    static let callout = jost(16, relativeTo: .callout)
    static let footnote = jost(14, relativeTo: .footnote)
    /// Readout numbers: Jost medium with tabular digits.
    static func number(_ size: CGFloat = 22, relativeTo style: Font.TextStyle = .title3) -> Font {
        jost(size, .medium, relativeTo: style).monospacedDigit()
    }
}

/// Uppercase, tightly tracked label.
struct TrackedText: View {
    let text: String
    var color: Color = Theme.inkSecondary
    var size: CGFloat = 12
    init(_ text: String, color: Color = Theme.inkSecondary, size: CGFloat = 12) {
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

/// White panel, 2 pt black frame, optional primary field across the top above a black rule.
struct PanelModifier: ViewModifier {
    var accent: Color?
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if let accent {
                accent.frame(height: Theme.heavy)
                Theme.ink.frame(height: Theme.rule)
            }
            content
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.ground)
        .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.rule))
    }
}

extension View {
    func panel(accent: Color? = nil, padding: CGFloat = 16) -> some View {
        modifier(PanelModifier(accent: accent, padding: padding))
    }

    /// Standard page frame: white ground edge to edge, content capped and centred on the grid.
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
    var color: Color = Theme.ink
    var height: CGFloat = Theme.rule
    var body: some View { color.frame(height: height).accessibilityHidden(true) }
}

struct VRule: View {
    var color: Color = Theme.ink
    var width: CGFloat = Theme.rule
    var body: some View { color.frame(width: width).accessibilityHidden(true) }
}

// MARK: - Headers

/// Index and tracked kicker, a big Jost display title, then a heavy black rule led by a primary block.
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
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 0) {
                accent.frame(width: 72)
                Theme.ink
            }
            .frame(height: Theme.heavy)
            .accessibilityHidden(true)
        }
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

/// Section heading in Jost bold, with an optional secondary line.
struct SectionTitle: View {
    let text: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text).font(BFont.heading()).foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle).font(BFont.footnote).foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Footnote-sized explanatory text.
struct Note: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(BFont.footnote).foregroundStyle(Theme.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Readouts

/// Tracked label over a Jost number. `marker` puts a thick primary bar beside the value, which is how a
/// readout carries a colour meaning without colouring small type on white.
struct Readout: View {
    let label: String
    let value: String
    var marker: Color? = nil
    var size: CGFloat = 22
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TrackedText(label, size: 11)
                .lineLimit(1).minimumScaleFactor(0.7)
            HStack(spacing: 8) {
                if let marker { marker.frame(width: Theme.heavy).accessibilityHidden(true) }
                Text(value)
                    .font(BFont.number(size))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            .fixedSize(horizontal: false, vertical: true)
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

/// A fader: 2 pt black track, a thick primary fill and a black vertical handle bar.
struct BauhausSlider: View {
    @Environment(\.dynamicTypeSize) private var dts
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var accent: Color = Theme.blue
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
                    .font(BFont.number(15, relativeTo: .footnote))
                    .foregroundStyle(Theme.ink)
                    .fixedSize()
            }
            GeometryReader { geo in
                let w = geo.size.width
                let x = w * fraction
                ZStack(alignment: .leading) {
                    Theme.ink.frame(height: Theme.rule)
                    accent.frame(width: x, height: Theme.heavy)
                    Theme.ink.frame(width: 8, height: 30)
                        .offset(x: min(max(0, x - 4), w - 8))
                }
                .frame(width: w, height: geo.size.height)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                    let f = min(max(g.location.x / max(w, 1), 0), 1)
                    value = range.lowerBound + f * (range.upperBound - range.lowerBound)
                })
            }
            .frame(height: 34)
        }
        .accessibilityRepresentation {
            Slider(value: $value, in: range) { Text(label) }
                .accessibilityValue(format(value))
        }
    }
}

/// Two adjoining OFF / ON segments in a 2 pt black frame; the active side is a flat field.
struct BauhausToggleStyle: ToggleStyle {
    var accent: Color = Theme.red
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(alignment: .center, spacing: 12) {
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 0) {
                    segment("Off", active: !configuration.isOn, field: Theme.ink)
                    VRule()
                    segment("On", active: configuration.isOn, field: accent)
                }
                .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.rule))
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
            .font(BFont.label(13))
            .tracking(1.6)
            .foregroundStyle(active ? Theme.ground : Theme.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: Theme.tapTarget)
            .background(active ? field : Theme.ground)
    }
}

/// Square button: a flat primary or black field, or white with a 2 pt black frame.
struct BauhausButtonStyle: ButtonStyle {
    enum Kind { case filled(Color), outline }
    var kind: Kind
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        let fill: Color
        switch kind {
        case .filled(let c): fill = c
        case .outline: fill = Theme.ground
        }
        return configuration.label
            .font(BFont.label(compact ? 13 : 15, relativeTo: compact ? .caption : .callout))
            .tracking(1.2)
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(Theme.onField(fill))
            .padding(.horizontal, compact ? 12 : 18)
            .frame(minHeight: compact ? 36 : Theme.tapTarget)
            .background(fill)
            .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.rule))
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == BauhausButtonStyle {
    static func bauhaus(_ kind: BauhausButtonStyle.Kind, compact: Bool = false) -> BauhausButtonStyle {
        BauhausButtonStyle(kind: kind, compact: compact)
    }
}

/// A flat field of colour holding one SF Symbol, used as a key or row marker.
struct GlyphTile: View {
    let glyph: String
    var fill: Color = Theme.blue
    var size: CGFloat = 26
    var body: some View {
        Image(systemName: glyph)
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundStyle(Theme.onField(fill))
            .frame(width: size, height: size)
            .background(fill)
            .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.rule))
            .accessibilityHidden(true)
    }
}

/// Legend / key row: a glyph tile in the series colour, then a tracked label.
struct KeyRow: View {
    let glyph: String
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            GlyphTile(glyph: glyph, fill: color, size: 24)
            TrackedText(text, color: Theme.ink, size: 11)
        }
    }
}

/// The real app icon in a 2 pt frame, used wherever a brand mark appears.
struct BrandMark: View {
    var size: CGFloat = 56
    var body: some View {
        Image("BrandMark")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.rule))
            .accessibilityLabel("Orch-OR app icon")
    }
}
