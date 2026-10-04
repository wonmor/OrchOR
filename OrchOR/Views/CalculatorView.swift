import SwiftUI

/// Diósi–Penrose objective-reduction calculator, calibrated as in Hameroff & Penrose (2014).
struct CalculatorView: View {
    @State private var logN: Double = log10(2e10)
    @State private var fractionExponent: Double = -3   // fraction of a neuron's tubulins that take part

    private var n: Double { pow(10, logN) }
    private var eG: Double { Physics.gravitationalSelfEnergy(tubulins: n) }
    private var tau: Double { Physics.collapseTime(tubulins: n) }
    private var neurons: Double { n / (Physics.tubulinsPerNeuron * pow(10, fractionExponent)) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.gradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "τ ≈ ħ / E_G", subtitle: "How long a superposition of N tubulins survives before objective reduction")
                            LabeledSlider(label: "Tubulins in coherent superposition", value: $logN, range: 6 ... 13) { "10^\(String(format: "%.1f", $0)) = \(pow(10, $0).sci("", digits: 1))" }
                            HStack {
                                Readout(label: "E_G", value: eG.sci("J"))
                                Readout(label: "τ", value: tau.timeString, color: Theme.amber)
                                Readout(label: "rate", value: tau.isFinite ? String(format: "%.1f Hz", 1 / tau) : "—", color: Theme.teal)
                            }
                            Text("Calibration: Hameroff & Penrose (2014) estimate that ~2×10¹⁰ tubulins, each displaced by about the width of an atomic nucleus, give τ ≈ 25 ms, the period of 40 Hz gamma synchrony.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .card()

                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "Timescales on a log axis", subtitle: "The whole argument is about whether coherence lasts long enough")
                            LogScaleBars(items: [
                                ("your τ", tau, Theme.amber),
                                ("25 ms (40 Hz)", 0.025, Theme.teal),
                                ("500 ms (pre-conscious)", 0.5, Theme.teal.opacity(0.6)),
                                ("Hagan et al. decoherence", Physics.haganDecoherence, Theme.rose.opacity(0.8)),
                                ("Tegmark decoherence", Physics.tegmarkDecoherence, Theme.rose),
                            ])
                            Text("For Orch-OR to work, the decoherence time must exceed τ. Tegmark (2000) put decoherence at 10⁻¹³ s; Hagan, Hameroff & Tuszynski (2002) argued for 10⁻⁵ to 10⁻⁴ s with shielding by ordered water and counter-ions. Even the friendlier number is far below 25 ms, which is why the theory remains contested.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .card()

                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "How many neurons?", subtitle: "A neuron holds ~10⁹ tubulins; only some would participate")
                            LabeledSlider(label: "Fraction of each neuron's tubulins involved", value: $fractionExponent, range: -5 ... 0) { String(format: "%.3g%%", pow(10, $0) * 100) }
                            Readout(label: "neurons needed", value: neurons.sci("neurons", digits: 1), color: Theme.violet)
                            Text("With 0.1% of tubulins per neuron, 2×10¹⁰ tubulins means about 20,000 neurons: the figure Hameroff & Penrose quote for one 25 ms conscious moment.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .card()
                    }
                    .padding()
                }
            }
            .navigationTitle("Calculator")
        }
    }
}

struct LogScaleBars: View {
    let items: [(String, Double, Color)]
    private let lo = -14.0, hi = 1.0

    var body: some View {
        VStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 8) {
                    Text(item.0).font(.caption2).frame(width: 120, alignment: .leading).lineLimit(2)
                    GeometryReader { geo in
                        let x = item.1.isFinite ? (log10(item.1) - lo) / (hi - lo) : 1
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.06))
                            Capsule().fill(item.2).frame(width: max(4, geo.size.width * min(max(x, 0), 1)))
                        }
                    }
                    .frame(height: 10)
                    Text(item.1.timeString).font(.caption2.monospaced()).frame(width: 64, alignment: .trailing)
                }
            }
            HStack { Text("10⁻¹⁴ s").font(.caption2); Spacer(); Text("10 s").font(.caption2) }.foregroundStyle(.secondary)
        }
    }
}
