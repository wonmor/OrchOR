import SwiftUI

struct ContentView: View {
    @Environment(OrchORSimulation.self) private var sim
    @State private var tab = min(max(UserDefaults.standard.integer(forKey: "tab"), 0), 3)

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case 0: MicrotubuleView()
                case 1: TimelineView()
                case 2: CalculatorView()
                default: LearnView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Keep scrolled content from drawing under the status bar: an ink strip fills the top safe area.
            .overlay(alignment: .top) {
                Color.clear.frame(height: 0)
                    .background(Theme.ink.ignoresSafeArea(edges: .top))
            }
            BauhausTabBar(selection: $tab)
        }
        .background(Theme.ink.ignoresSafeArea())
        .tint(Theme.yellow)
        .onChange(of: tab) { _, t in UserDefaults.standard.set(t, forKey: "tab") }
        .task {
            // Drive the simulation at ~30 fps while the app is in the foreground.
            var last = Date()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                let now = Date()
                sim.tick(realDt: min(0.1, now.timeIntervalSince(last)))
                last = now
            }
        }
    }
}

/// Flat ink bar, 2 pt top rule, four columns split by 2 pt rules. The active column carries a thick
/// colour bar along its top edge. Glyphs are SF Symbols line glyphs.
struct BauhausTabBar: View {
    @Binding var selection: Int

    private struct Item { let title: String; let glyph: String; let accent: Color }
    private let items: [Item] = [
        Item(title: "Microtubule", glyph: "view.3d", accent: Theme.blue),
        Item(title: "Timeline", glyph: "waveform.path.ecg", accent: Theme.yellow),
        Item(title: "Calculator", glyph: "function", accent: Theme.red),
        Item(title: "Learn", glyph: "book", accent: Theme.paper),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HRule(color: Theme.paper.opacity(0.9))
            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    if i > 0 { Theme.rule.frame(width: Theme.ruleWidth).accessibilityHidden(true) }
                    button(i)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .background(Theme.ink.ignoresSafeArea(edges: .bottom))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tabs")
    }

    private func button(_ i: Int) -> some View {
        let item = items[i]
        let on = selection == i
        return Button { selection = i } label: {
            VStack(spacing: 6) {
                (on ? item.accent : Color.clear).frame(height: Theme.barHeight)
                Image(systemName: item.glyph)
                    .font(.system(size: 20, weight: on ? .semibold : .regular))
                    .frame(height: 24)
                Text(Theme.caps(item.title))
                    .font(BFont.label(11, relativeTo: .caption2))
                    .tracking(1.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 8)
            }
            .foregroundStyle(on ? Theme.paper : Theme.muted)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
    }
}
