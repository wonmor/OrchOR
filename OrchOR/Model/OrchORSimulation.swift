import Foundation
import Observation

struct OREvent: Identifiable {
    let id = UUID()
    let simTime: Double        // seconds of simulated time
    let tubulins: Int          // displayed dimers that collapsed
    let effectiveTubulins: Double
    let tau: Double
}

struct HistoryPoint: Identifiable {
    let id: Int
    let simTime: Double
    let superposed: Int
}

/// A toy model of Orchestrated Objective Reduction on a single microtubule lattice.
///
/// Each displayed tubulin dimer stands in for `10^representationExponent` real dimers spread across many
/// neurons, so the lattice can reach the ~2×10¹⁰ tubulins Hameroff & Penrose associate with a 25 ms event.
/// Superposition spreads between neighbours ("orchestration"), gravitational self-energy E_G accumulates,
/// and when ∫E_G dt reaches ħ the whole coherent set undergoes objective reduction.
@Observable
@MainActor
final class OrchORSimulation {
    enum DimerState: UInt8 { case a = 0, b = 1, superposed = 2 }

    // Lattice geometry: 13 protofilaments, `rings` dimers along each.
    let protofilaments = 13
    let rings = 30
    var count: Int { protofilaments * rings }

    private(set) var states: [DimerState]
    private(set) var phase: [Float]            // 0…1 pulsing for superposed dimers
    private(set) var flash: Float = 0          // 1 right after an OR event, decays
    private(set) var lastCollapsed: [Bool]

    // Controls
    var orchestration: Double = 0.6            // 0…1, how strongly neighbours recruit each other
    var representationExponent: Double = 7.7   // each displayed dimer = 10^x real dimers
    var decoherenceEnabled = false
    var decoherenceExponent: Double = -4       // log10 seconds (Hagan: -4, Tegmark: -13)
    var slowMotion: Double = 40                // 1 real second shows 1/slowMotion simulated seconds
    var running = true

    // Readouts
    private(set) var simTime: Double = 0
    private(set) var superposedCount = 0
    private(set) var action: Double = 0        // ∫E_G dt, J·s
    private(set) var events: [OREvent] = []
    private(set) var history: [HistoryPoint] = []
    private var historyCounter = 0
    private var lastSampleTime: Double = -1

    var effectiveTubulins: Double { Double(superposedCount) * pow(10, representationExponent) }
    var gravitationalSelfEnergy: Double { Physics.gravitationalSelfEnergy(tubulins: effectiveTubulins) }
    var tau: Double { Physics.collapseTime(tubulins: effectiveTubulins) }
    var progressToCollapse: Double { min(1, action / Physics.hbar) }
    var decoherenceTime: Double { pow(10, decoherenceExponent) }
    var eventFrequencyHz: Double? {
        guard events.count >= 2 else { return nil }
        let recent = events.suffix(6)
        let span = recent.last!.simTime - recent.first!.simTime
        return span > 0 ? Double(recent.count - 1) / span : nil
    }

    init() {
        states = [DimerState](repeating: .a, count: 13 * 30)
        phase = [Float](repeating: 0, count: 13 * 30)
        lastCollapsed = [Bool](repeating: false, count: 13 * 30)
        for i in 0 ..< states.count where Bool.random() { states[i] = .b }
    }

    func reset() {
        for i in 0 ..< states.count { states[i] = Bool.random() ? .a : .b; phase[i] = 0; lastCollapsed[i] = false }
        superposedCount = 0; action = 0; simTime = 0; flash = 0
        events = []; history = []; historyCounter = 0; lastSampleTime = -1
    }

    func index(proto: Int, ring: Int) -> Int { ring * protofilaments + proto }

    private func neighbours(of i: Int) -> [Int] {
        let p = i % protofilaments, r = i / protofilaments
        var n: [Int] = []
        if r > 0 { n.append(index(proto: p, ring: r - 1)) }
        if r < rings - 1 { n.append(index(proto: p, ring: r + 1)) }
        n.append(index(proto: (p + 1) % protofilaments, ring: r))
        n.append(index(proto: (p + protofilaments - 1) % protofilaments, ring: r))
        return n
    }

    /// Advance by `realDt` seconds of wall-clock time.
    func tick(realDt: Double) {
        guard running else { return }
        let dt = realDt / slowMotion              // simulated seconds
        simTime += dt
        let dtMs = dt * 1000

        // 1. Spontaneous seeds: a few dimers enter superposition on their own.
        let seedRate = 0.03 * dtMs
        if Double.random(in: 0 ..< 1) < seedRate {
            let i = Int.random(in: 0 ..< count)
            if states[i] != .superposed { states[i] = .superposed; phase[i] = Float.random(in: 0 ..< 1) }
        }

        // 2. Orchestration: superposed dimers recruit neighbours.
        let recruit = min(1, orchestration * 0.5 * dtMs)
        var newly: [Int] = []
        for i in 0 ..< count where states[i] == .superposed {
            for n in neighbours(of: i) where states[n] != .superposed && Double.random(in: 0 ..< 1) < recruit {
                newly.append(n)
            }
        }
        for n in newly { states[n] = .superposed; phase[n] = Float.random(in: 0 ..< 1) }

        // 3. Environmental decoherence, if enabled: superpositions die at rate 1/t_dec.
        if decoherenceEnabled {
            let p = min(1, dt / decoherenceTime)
            for i in 0 ..< count where states[i] == .superposed && Double.random(in: 0 ..< 1) < p {
                states[i] = Bool.random() ? .a : .b
            }
        }

        // 4. Count, accumulate action, pulse.
        superposedCount = states.reduce(0) { $0 + ($1 == .superposed ? 1 : 0) }
        action += gravitationalSelfEnergy * dt
        if superposedCount == 0 { action = 0 }
        let pulse = Float(dt * 1000 * 0.12)
        for i in 0 ..< count where states[i] == .superposed { phase[i] = (phase[i] + pulse).truncatingRemainder(dividingBy: 1) }
        flash = max(0, flash - Float(realDt * 2.5))
        if flash == 0, lastCollapsed.contains(true) { for i in 0 ..< count { lastCollapsed[i] = false } }

        // 5. Objective reduction when ∫E_G dt ≥ ħ.
        if action >= Physics.hbar && superposedCount > 0 {
            let n = superposedCount
            events.append(OREvent(simTime: simTime, tubulins: n, effectiveTubulins: effectiveTubulins, tau: tau))
            for i in 0 ..< count {
                lastCollapsed[i] = states[i] == .superposed
                if states[i] == .superposed { states[i] = Bool.random() ? .a : .b }
            }
            superposedCount = 0
            action = 0
            flash = 1
            if events.count > 200 { events.removeFirst() }
        }

        // 6. History sample every 0.5 simulated ms.
        if simTime - lastSampleTime >= 0.0005 {
            history.append(HistoryPoint(id: historyCounter, simTime: simTime, superposed: superposedCount))
            historyCounter += 1
            lastSampleTime = simTime
            if history.count > 400 { history.removeFirst() }
        }
    }
}
