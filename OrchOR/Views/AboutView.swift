import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(v) (\(b))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(index: "00", kicker: "About", title: "orch-or", accent: Theme.yellow) {
                    Button { dismiss() } label: { Label("Close", systemImage: "xmark") }
                        .buttonStyle(.bauhaus(.outline(Theme.paper), compact: true))
                }
                HStack(alignment: .center, spacing: 14) {
                    BrandMark(size: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Orch-OR Visualizer").font(BFont.heading()).foregroundStyle(Theme.paper)
                        TrackedText("Version \(version)", size: 11)
                    }
                }
                .panel()
                block("What it is", accent: Theme.blue,
                      "An interactive model of the Penrose–Hameroff theory of consciousness: microtubules, tubulin superposition, and objective reduction.")
                block("What the simulation is, and isn't", accent: Theme.red,
                      "The lattice, the growth of coherence and the collapse rule ∫E_G dt ≥ ħ follow the theory's own description, with the Diósi–Penrose timescale calibrated to Hameroff & Penrose (2014). Recruitment rates, seeding and the choice of post-collapse states are illustrative. It is a teaching model, not a physical simulation, and the theory itself is contested; see the Learn tab for both sides.")
                block("Privacy", accent: Theme.yellow,
                      "The app runs entirely on your device and collects no data.")
            }
            .pageFrame()
        }
        .background(Theme.ink.ignoresSafeArea())
        .presentationBackground(Theme.ink)
    }

    private func block(_ title: String, accent: Color, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(BFont.heading()).foregroundStyle(Theme.paper).accessibilityAddTraits(.isHeader)
            Text(body).font(.callout).foregroundStyle(Theme.paper.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
        }
        .panel(accent: accent)
    }
}
