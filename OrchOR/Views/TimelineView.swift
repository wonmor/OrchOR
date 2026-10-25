import SwiftUI
import Charts

/// Coherence over simulated time, with objective-reduction events marked.
struct TimelineView: View {
    @Environment(OrchORSimulation.self) private var sim
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(index: "02", kicker: "Coherence over time", title: "timeline", accent: Theme.yellow)
                chartPanel
                if hSize == .regular {
                    HStack(alignment: .top, spacing: 16) {
                        momentsPanel
                        ratePanel.frame(width: 360)
                    }
                } else {
                    ratePanel
                    momentsPanel
                }
            }
            .pageFrame()
        }
        .background(Theme.ink)
    }

    private var chartPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Coherent superposition", subtitle: "Dimers in superposition, with each objective-reduction event as a vertical red rule")
            HStack(spacing: 18) {
                KeyRow(glyph: "arrow.up.arrow.down", color: Theme.yellow, text: "Superposed dimers")
                KeyRow(glyph: "bolt", color: Theme.redText, text: "OR event")
            }
            chart.frame(height: hSize == .regular ? 360 : 240)
        }
        .panel(accent: Theme.yellow)
    }

    private var chart: some View {
        Chart {
            ForEach(sim.history) { p in
                AreaMark(x: .value("t", p.simTime * 1000), y: .value("superposed", p.superposed))
                    .foregroundStyle(Theme.yellow.opacity(0.22))
                LineMark(x: .value("t", p.simTime * 1000), y: .value("superposed", p.superposed))
                    .foregroundStyle(Theme.yellow)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .butt, lineJoin: .miter))
            }
            ForEach(sim.events.filter { e in sim.history.first.map { e.simTime >= $0.simTime } ?? false }) { e in
                RuleMark(x: .value("event", e.simTime * 1000))
                    .foregroundStyle(Theme.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Theme.rule)
                AxisTick(length: 6, stroke: StrokeStyle(lineWidth: 2)).foregroundStyle(Theme.paper)
                AxisValueLabel().font(.system(.caption2, design: .monospaced)).foregroundStyle(Theme.muted)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Theme.rule)
                AxisValueLabel().font(.system(.caption2, design: .monospaced)).foregroundStyle(Theme.muted)
            }
        }
        .chartXAxisLabel(position: .bottom, alignment: .leading) { TrackedText("Simulated time · ms", size: 11) }
        .chartYAxisLabel(position: .leading, alignment: .top) { TrackedText("Dimers", size: 11) }
        .chartXScale(domain: .automatic(includesZero: false))
        .chartYScale(domain: 0 ... sim.count)
        .chartPlotStyle { plot in
            plot.background(Theme.ink)
                .overlay(alignment: .bottom) { Theme.paper.frame(height: Theme.ruleWidth) }
                .overlay(alignment: .leading) { Theme.paper.frame(width: Theme.ruleWidth) }
        }
        .accessibilityLabel("Chart of superposed dimers over simulated time")
        .accessibilityValue("\(sim.events.count) objective-reduction events so far")
    }

    private var ratePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            TrackedText("Current event rate")
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(sim.eventFrequencyHz.map { String(format: "%.0f", $0) } ?? "—")
                    .font(BFont.display(64))
                    .foregroundStyle(Theme.paper)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text("Hz").font(BFont.heading()).foregroundStyle(Theme.muted)
            }
            HRule()
            Text("Hameroff & Penrose associate conscious moments with gamma synchrony, roughly 40 Hz: one event every 25 ms.")
                .font(.footnote).foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .panel(accent: Theme.blue)
    }

    private var momentsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Recent moments", subtitle: "Each OR event is, in the theory, a discrete moment of experience")
            if sim.events.isEmpty {
                Text("No events yet. Let the simulation run on the Microtubule tab.")
                    .font(.footnote).foregroundStyle(Theme.muted)
            } else {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        TrackedText("t", size: 11)
                        TrackedText("Dimers", size: 11)
                        TrackedText("Tubulins", size: 11)
                        TrackedText("τ", size: 11).gridColumnAlignment(.trailing)
                    }
                    GridRow { HRule(color: Theme.paper.opacity(0.9)).gridCellColumns(4) }
                    ForEach(sim.events.suffix(8).reversed()) { e in
                        GridRow {
                            Text(String(format: "%.1f ms", e.simTime * 1000))
                            Text("\(e.tubulins)")
                            Text(e.effectiveTubulins.compact)
                            Text(e.tau.timeString).foregroundStyle(Theme.yellow).gridColumnAlignment(.trailing)
                        }
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(Theme.paper)
                        .accessibilityElement(children: .combine)
                        GridRow { HRule(height: 1).gridCellColumns(4) }
                    }
                }
            }
        }
        .panel(accent: Theme.red)
    }
}
