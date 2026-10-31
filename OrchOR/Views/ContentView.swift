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
            // Keep scrolled content from drawing under the status bar: a white strip fills the top safe area.
            .overlay(alignment: .top) {
                Color.clear.frame(height: 0)
                    .background(Theme.ground.ignoresSafeArea(edges: .top))
            }
            BauhausTabBar(selection: $tab)
        }
        .background(Theme.ground.ignoresSafeArea())
        .font(BFont.body)
        .foregroundStyle(Theme.ink)
        .tint(Theme.blue)
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

/// White bar under a 4 pt black rule, four columns split by 2 pt rules. The selected column is a flat
/// blue field (blue means selection throughout the app). Glyphs are SF Symbols.
struct BauhausTabBar: View {
    @Binding var selection: Int

    private struct Item { let title: String; let glyph: String }
    private let items: [Item] = [
        Item(title: "Microtubule", glyph: "view.3d"),
        Item(title: "Timeline", glyph: "waveform.path.ecg"),
        Item(title: "Calculator", glyph: "function"),
        Item(title: "Learn", glyph: "book"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HRule(height: Theme.thick)
            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    if i > 0 { VRule() }
                    button(i)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .background(Theme.ground.ignoresSafeArea(edges: .bottom))
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tabs")
    }

    private func button(_ i: Int) -> some View {
        let item = items[i]
        let on = selection == i
        return Button { selection = i } label: {
            VStack(spacing: 4) {
                Image(systemName: item.glyph)
                    .font(.system(size: 20, weight: on ? .bold : .regular))
                    .frame(height: 24)
                Text(Theme.caps(item.title))
                    .font(BFont.label(11, relativeTo: .caption2))
                    .tracking(1.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 4)
            }
            .padding(.vertical, 10)
            .foregroundStyle(on ? Theme.ground : Theme.ink)
            .frame(maxWidth: .infinity)
            .background(on ? Theme.blue : Theme.ground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
    }
}
