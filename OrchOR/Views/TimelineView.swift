import SwiftUI
import Charts

/// Coherence over simulated time, with objective-reduction events marked.
struct TimelineView: View {
    @Environment(OrchORSimulation.self) private var sim

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.gradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(text: "Coherent superposition over time",
                                         subtitle: "Dimers in superposition (violet) and OR events (white lines)")
                            chart.frame(height: 220)
                        }
                        .card()
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(text: "Recent 'moments'", subtitle: "Each OR event is, in the theory, a discrete moment of experience")
                            if sim.events.isEmpty {
                                Text("No events yet. Let the simulation run on the Microtubule tab.").font(.footnote).foregroundStyle(.secondary)
                            } else {
                                ForEach(sim.events.suffix(8).reversed()) { e in
                                    HStack {
                                        Text(String(format: "t = %.1f ms", e.simTime * 1000)).font(.caption.monospaced())
                                        Spacer()
                                        Text("\(e.tubulins) dimers · \(e.effectiveTubulins.compact)").font(.caption).foregroundStyle(.secondary)
                                        Text("τ \(e.tau.timeString)").font(.caption.monospaced()).foregroundStyle(Theme.amber)
                                    }
                                }
                            }
                            if let f = sim.eventFrequencyHz {
                                Text(String(format: "Current rate ≈ %.0f Hz. Hameroff & Penrose associate conscious moments with gamma synchrony, roughly 40 Hz, i.e. one event every 25 ms.", f))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .card()
                    }
                    .padding()
                }
            }
            .navigationTitle("Timeline")
        }
    }

    private var chart: some View {
        Chart {
            ForEach(sim.history) { p in
                AreaMark(x: .value("t", p.simTime * 1000), y: .value("superposed", p.superposed))
                    .foregroundStyle(LinearGradient(colors: [Theme.violet.opacity(0.6), Theme.violet.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("t", p.simTime * 1000), y: .value("superposed", p.superposed))
                    .foregroundStyle(Theme.violet)
            }
            ForEach(sim.events.filter { e in sim.history.first.map { e.simTime >= $0.simTime } ?? false }) { e in
                RuleMark(x: .value("event", e.simTime * 1000)).foregroundStyle(.white.opacity(0.8)).lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartXAxisLabel("simulated time (ms)")
        .chartYAxisLabel("dimers")
        .chartYScale(domain: 0 ... sim.count)
    }
}
