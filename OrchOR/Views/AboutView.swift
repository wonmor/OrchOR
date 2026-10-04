import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.gradient.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Orch-OR").font(.title2.weight(.bold))
                            Text("An interactive model of the Penrose–Hameroff theory of consciousness: microtubules, tubulin superposition, and objective reduction.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }.card()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("What the simulation is, and isn't").font(.headline)
                            Text("The lattice, the growth of coherence and the collapse rule ∫E_G dt ≥ ħ follow the theory's own description, with the Diósi–Penrose timescale calibrated to Hameroff & Penrose (2014). Recruitment rates, seeding and the choice of post-collapse states are illustrative. It is a teaching model, not a physical simulation, and the theory itself is contested; see the Learn tab for both sides.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }.card()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Privacy").font(.headline)
                            Text("The app runs entirely on your device and collects no data.").font(.footnote).foregroundStyle(.secondary)
                        }.card()
                    }.padding()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
