import SwiftUI

/// The tip jar panel shown in About. Prices come from the App Store; nothing here unlocks anything.
struct TipJarPanel: View {
    @Environment(TipJarStore.self) private var store
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                GlyphTile(glyph: "cup.and.saucer.fill", fill: Theme.yellow, size: 30)
                Text("Tip Jar").font(BFont.heading()).foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
            }
            Text("Orch-OR is free, with no ads and no tracking. If it has been useful, you can leave a tip to support its development.")
                .font(BFont.callout).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            if store.status == .thanked {
                thanks
            } else {
                choices
            }

            switch store.status {
            case .pending: message(TipJar.pending, glyph: "hourglass", fill: Theme.yellow)
            case .failed(let text): message(text, glyph: "exclamationmark", fill: Theme.red)
            default: EmptyView()
            }

            Note(TipJar.disclaimer)
        }
        .panel(accent: Theme.blue)
        .task { store.start() }
    }

    @ViewBuilder private var choices: some View {
        switch store.load {
        case .loading:
            HStack(spacing: 10) {
                ProgressView().tint(Theme.ink)
                TrackedText("Loading prices", size: 11)
            }
            .frame(minHeight: Theme.tapTarget)
        case .unavailable:
            VStack(alignment: .leading, spacing: 10) {
                Note(TipJar.unavailable)
                Button { Task { await store.loadProducts() } } label: { Label("Try again", systemImage: "arrow.clockwise") }
                    .buttonStyle(.bauhaus(.outline, compact: true))
            }
        case .ready:
            let columns = hSize == .regular ? [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                                            : [GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(store.options) { option in tipButton(option) }
            }
        }
    }

    private func tipButton(_ option: TipOption) -> some View {
        let busy = store.status == .purchasing(option.id)
        let anyBusy: Bool = { if case .purchasing = store.status { return true } else { return false } }()
        return Button { Task { await store.tip(option) } } label: {
            HStack(spacing: 10) {
                Text(option.name)
                Spacer(minLength: 8)
                if busy {
                    ProgressView().tint(Theme.ground)
                } else {
                    Text(option.displayPrice).monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bauhaus(busy ? .filled(Theme.blue) : .outline))
        .disabled(anyBusy)
        .accessibilityLabel("\(option.name), \(option.displayPrice)")
        .accessibilityHint("Leaves a tip. Unlocks nothing.")
    }

    private var thanks: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                GlyphTile(glyph: "heart.fill", fill: Theme.red, size: 44)
                Text("Thank you").font(BFont.display(34, relativeTo: .title)).foregroundStyle(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
            }
            Text(TipJar.thanks).font(BFont.callout).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button { store.dismissMessage() } label: { Label("Done", systemImage: "checkmark") }
                .buttonStyle(.bauhaus(.outline, compact: true))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.soft)
        .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.rule))
    }

    private func message(_ text: String, glyph: String, fill: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            GlyphTile(glyph: glyph, fill: fill, size: 26)
            Text(text).font(BFont.footnote).foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button { store.dismissMessage() } label: { Image(systemName: "xmark") }
                .buttonStyle(.plain)
                .frame(width: Theme.tapTarget, height: Theme.tapTarget)
                .accessibilityLabel("Dismiss")
        }
    }
}

/// The tip jar on its own, opened from the small link at the foot of the Learn tab.
struct TipJarSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(index: "00", kicker: "Support Orch-OR", title: "tip jar", accent: Theme.blue) {
                    Button { dismiss() } label: { Label("Close", systemImage: "xmark") }
                        .buttonStyle(.bauhaus(.outline, compact: true))
                }
                TipJarPanel()
            }
            .pageFrame()
        }
        .background(Theme.ground.ignoresSafeArea())
        .presentationBackground(Theme.ground)
        .presentationCornerRadius(0)
    }
}

/// A small, quiet text link. No banner, no badge, no prompt.
struct SupportLink: View {
    @State private var open = false
    var body: some View {
        Button { open = true } label: {
            Label("Support Orch-OR", systemImage: "cup.and.saucer")
                .font(BFont.footnote)
                .foregroundStyle(Theme.inkSecondary)
                .underline()
                .frame(minHeight: Theme.tapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the tip jar")
        .sheet(isPresented: $open) { TipJarSheet() }
    }
}
