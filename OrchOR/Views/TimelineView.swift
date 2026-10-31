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
        .background(Theme.ground)
    }

    private var chartPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Coherent superposition", subtitle: "Dimers in superposition, with each objective-reduction event as a vertical red rule")
            HStack(spacing: 18) {
                KeyRow(glyph: "arrow.up.arrow.down", color: Theme.yellow, text: "Superposed dimers")
                KeyRow(glyph: "bolt", color: Theme.red, text: "OR event")
            }
            chart.frame(height: hSize == .regular ? 360 : 240)
        }
        .panel(accent: Theme.yellow)
    }

    private var chart: some View {
        Chart {
            ForEach(sim.history) { p in
                AreaMark(x: .value("t", p.simTime * 1000), y: .value("superposed", p.superposed))
                    .foregroundStyle(Theme.yellow.opacity(0.55))
                LineMark(x: .value("t", p.simTime * 1000), y: .value("superposed", p.superposed))
                    .foregroundStyle(Theme.ink)
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
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Theme.hairline)
                AxisTick(length: 6, stroke: StrokeStyle(lineWidth: 2)).foregroundStyle(Theme.ink)
                AxisValueLabel().font(BFont.number(11, relativeTo: .caption2)).foregroundStyle(Theme.inkSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Theme.hairline)
                AxisValueLabel().font(BFont.number(11, relativeTo: .caption2)).foregroundStyle(Theme.inkSecondary)
            }
        }
        .chartXAxisLabel(position: .bottom, alignment: .leading) { TrackedText("Simulated time (ms)", size: 11) }
        .chartYAxisLabel(position: .leading, alignment: .top) { TrackedText("Dimers", size: 11) }
        .chartXScale(domain: .automatic(includesZero: false))
        .chartYScale(domain: 0 ... sim.count)
        .chartPlotStyle { plot in
            plot.background(Theme.ground)
                .overlay(alignment: .bottom) { Theme.ink.frame(height: Theme.rule) }
                .overlay(alignment: .leading) { Theme.ink.frame(width: Theme.rule) }
        }
        .accessibilityLabel("Chart of superposed dimers over simulated time")
        .accessibilityValue("\(sim.events.count) objective-reduction events so far")
    }

    private var ratePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            TrackedText("Current event rate")
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(sim.eventFrequencyHz.map { String(format: "%.0f", $0) } ?? "—")
                    .font(BFont.display(72))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text("Hz").font(BFont.heading()).foregroundStyle(Theme.inkSecondary)
            }
            HRule()
            Note("Hameroff & Penrose associate conscious moments with gamma synchrony, roughly 40 Hz: one event every 25 ms.")
        }
        .panel(accent: Theme.red)
    }

    private var momentsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Recent moments", subtitle: "Each OR event is, in the theory, a discrete moment of experience")
            if sim.events.isEmpty {
                Note("No events yet. Let the simulation run on the Microtubule tab.")
            } else {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        TrackedText("t", size: 11)
                        TrackedText("Dimers", size: 11)
                        TrackedText("Tubulins", size: 11)
                        TrackedText("τ", size: 11).gridColumnAlignment(.trailing)
                    }
                    GridRow { HRule().gridCellColumns(4) }
                    ForEach(sim.events.suffix(8).reversed()) { e in
                        GridRow {
                            Text(String(format: "%.1f ms", e.simTime * 1000))
                            Text("\(e.tubulins)")
                            Text(e.effectiveTubulins.compact)
                            Text(e.tau.timeString).fontWeight(.semibold).gridColumnAlignment(.trailing)
                        }
                        .font(BFont.number(14, relativeTo: .footnote))
                        .foregroundStyle(Theme.ink)
                        .accessibilityElement(children: .combine)
                        GridRow { HRule(color: Theme.hairline, height: 1).gridCellColumns(4) }
                    }
                }
            }
        }
        .panel(accent: Theme.red)
    }
}
