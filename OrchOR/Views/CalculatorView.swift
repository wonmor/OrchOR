import SwiftUI

/// Diósi–Penrose objective-reduction calculator, calibrated as in Hameroff & Penrose (2014).
struct CalculatorView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var logN: Double = log10(2e10)
    @State private var fractionExponent: Double = -3   // fraction of a neuron's tubulins that take part

    private var n: Double { pow(10, logN) }
    private var eG: Double { Physics.gravitationalSelfEnergy(tubulins: n) }
    private var tau: Double { Physics.collapseTime(tubulins: n) }
    private var neurons: Double { n / (Physics.tubulinsPerNeuron * pow(10, fractionExponent)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(index: "03", kicker: "Diósi–Penrose", title: "calculator", accent: Theme.red)
                if hSize == .regular {
                    HStack(alignment: .top, spacing: 16) {
                        tauPanel
                        VStack(spacing: 16) { timescalePanel; neuronPanel }
                    }
                } else {
                    tauPanel
                    timescalePanel
                    neuronPanel
                }
            }
            .pageFrame()
        }
        .background(Theme.ground)
    }

    private var tauPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            TrackedText("Collapse time")
            Text("τ ≈ ħ / E_G")
                .font(.system(size: 38, weight: .bold, design: .serif).italic())
                .foregroundStyle(Theme.ink)
                .accessibilityLabel("tau is approximately h-bar over E G")
            Note("How long a superposition of N tubulins survives before objective reduction.")
            HRule()
            BauhausSlider(label: "Tubulins in coherent superposition", value: $logN, range: 6 ... 13, accent: Theme.yellow) {
                pow(10, $0).sci("", digits: 1)
            }
            // Result block: τ on a flat yellow field, with N, E_G and rate beside it on the grid.
            VStack(alignment: .leading, spacing: 2) {
                TrackedText("τ", color: Theme.ink)
                Text(tau.timeString)
                    .font(BFont.display(40, relativeTo: .largeTitle).monospacedDigit())
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.yellow)
            .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.rule))
            .accessibilityElement(children: .combine)
            ReadoutRow {
                Readout(label: "N", value: n.sci("", digits: 1))
                Readout(label: "E_G", value: eG.sci("J", digits: 1))
                Readout(label: "Rate", value: tau.isFinite ? String(format: "%.1f Hz", 1 / tau) : "—", marker: Theme.red)
            }
            Note("Calibration: Hameroff & Penrose (2014) estimate that ~2×10¹⁰ tubulins, each displaced by about the width of an atomic nucleus, give τ ≈ 25 ms, the period of 40 Hz gamma synchrony.")
        }
        .panel(accent: Theme.yellow)
    }

    private var timescalePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Timescales on a log axis", subtitle: "The whole argument is about whether coherence lasts long enough")
            LogScaleBars(items: [
                ("Your τ", tau, Theme.yellow),
                ("25 ms – 40 Hz", 0.025, Theme.ink),
                ("500 ms – pre-conscious", 0.5, Theme.ink),
                ("Hagan et al. decoherence", Physics.haganDecoherence, Theme.red),
                ("Tegmark decoherence", Physics.tegmarkDecoherence, Theme.red),
            ])
            Note("For Orch-OR to work, the decoherence time must exceed τ. Tegmark (2000) put decoherence at 10⁻¹³ s; Hagan, Hameroff & Tuszynski (2002) argued for 10⁻⁵ to 10⁻⁴ s with shielding by ordered water and counter-ions. Even the friendlier number is far below 25 ms, which is why the theory remains contested.")
        }
        .panel(accent: Theme.red)
    }

    private var neuronPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "How many neurons?", subtitle: "A neuron holds ~10⁹ tubulins; only some would participate")
            BauhausSlider(label: "Fraction of each neuron's tubulins", value: $fractionExponent, range: -5 ... 0, accent: Theme.blue) {
                String(format: "%.3g%%", pow(10, $0) * 100)
            }
            Readout(label: "Neurons needed", value: neurons.sci("", digits: 1), size: 30)
            Note("With 0.1% of tubulins per neuron, 2×10¹⁰ tubulins means about 20,000 neurons: the figure Hameroff & Penrose quote for one 25 ms conscious moment.")
        }
        .panel(accent: Theme.blue)
    }
}

/// Horizontal log-scale bar chart: flat colour bars on a 2 pt black baseline, 10⁻¹⁴ s to 10 s.
struct LogScaleBars: View {
    let items: [(String, Double, Color)]
    private let lo = -14.0, hi = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        TrackedText(item.0, color: Theme.ink, size: 11)
                        Spacer(minLength: 8)
                        Text(item.1.timeString)
                            .font(BFont.number(13, relativeTo: .caption))
                            .foregroundStyle(Theme.ink)
                    }
                    GeometryReader { geo in
                        let x = item.1.isFinite ? (log10(item.1) - lo) / (hi - lo) : 1
                        ZStack(alignment: .leading) {
                            Theme.soft
                            item.2.frame(width: max(4, geo.size.width * min(max(x, 0), 1)))
                        }
                    }
                    .frame(height: 14)
                    .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: Theme.thin))
                }
                .accessibilityElement(children: .combine)
            }
            HRule()
            HStack {
                Text("10⁻¹⁴ s"); Spacer(); Text("10 s")
            }
            .font(BFont.number(11, relativeTo: .caption2))
            .foregroundStyle(Theme.inkSecondary)
            .accessibilityHidden(true)
        }
    }
}
