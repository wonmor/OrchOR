package com.johnseong.orchor.model

import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

data class OREvent(
    val simTime: Double,          // seconds of simulated time
    val tubulins: Int,            // displayed dimers that collapsed
    val effectiveTubulins: Double,
    val tau: Double,
)

data class HistoryPoint(val id: Int, val simTime: Double, val superposed: Int)

/**
 * An interactive model of Orchestrated Objective Reduction on a single microtubule lattice, ported line
 * for line from the iOS `OrchORSimulation` (same steps, same order of random draws).
 *
 * Each displayed tubulin dimer stands in for 10^representationExponent real dimers spread across many
 * neurons, so the lattice can reach the ~2×10¹⁰ tubulins Hameroff & Penrose associate with a 25 ms event.
 * Superposition spreads between neighbours ("orchestration"), gravitational self-energy E_G accumulates,
 * and when ∫E_G dt reaches ħ the whole coherent set undergoes objective reduction.
 */
class OrchORSimulation(seed: ULong = kotlin.random.Random.nextLong().toULong()) {
    companion object {
        const val A: Byte = 0
        const val B: Byte = 1
        const val SUPERPOSED: Byte = 2
    }

    // Lattice geometry: 13 protofilaments, `rings` dimers along each.
    val protofilaments = 13
    val rings = 30
    val count: Int get() = protofilaments * rings

    private val rng = SplitMix64(seed)
    val states = ByteArray(13 * 30)
    val phase = FloatArray(13 * 30)            // 0…1 pulsing for superposed dimers
    var flash = 0f                             // 1 right after an OR event, decays
        private set
    val lastCollapsed = BooleanArray(13 * 30)

    // Controls
    var orchestration = 0.6                    // 0…1, how strongly neighbours recruit each other
    var representationExponent = 7.7           // each displayed dimer = 10^x real dimers
    var decoherenceEnabled = false
    var decoherenceExponent = -4.0             // log10 seconds (Hagan: -4, Tegmark: -13)
    var slowMotion = 40.0                      // 1 real second shows 1/slowMotion simulated seconds
    var running = true

    // Readouts
    var simTime = 0.0
        private set
    var superposedCount = 0
        private set
    var action = 0.0                           // ∫E_G dt, J s
        private set
    val events = ArrayList<OREvent>()
    val history = ArrayList<HistoryPoint>()
    private var historyCounter = 0
    private var lastSampleTime = -1.0

    val effectiveTubulins: Double get() = superposedCount.toDouble() * 10.0.pow(representationExponent)
    val gravitationalSelfEnergy: Double get() = Physics.gravitationalSelfEnergy(effectiveTubulins)
    val tau: Double get() = Physics.collapseTime(effectiveTubulins)
    val progressToCollapse: Double get() = min(1.0, action / Physics.HBAR)
    val decoherenceTime: Double get() = 10.0.pow(decoherenceExponent)
    val eventFrequencyHz: Double?
        get() {
            if (events.size < 2) return null
            val recent = events.takeLast(6)
            val span = recent.last().simTime - recent.first().simTime
            return if (span > 0) (recent.size - 1).toDouble() / span else null
        }

    init {
        for (i in states.indices) if (rng.nextBool()) states[i] = B
    }

    fun reset() {
        for (i in states.indices) {
            states[i] = if (rng.nextBool()) A else B; phase[i] = 0f; lastCollapsed[i] = false
        }
        superposedCount = 0; action = 0.0; simTime = 0.0; flash = 0f
        events.clear(); history.clear(); historyCounter = 0; lastSampleTime = -1.0
    }

    fun index(proto: Int, ring: Int): Int = ring * protofilaments + proto

    private fun neighbours(i: Int): IntArray {
        val p = i % protofilaments
        val r = i / protofilaments
        val n = ArrayList<Int>(4)
        if (r > 0) n.add(index(p, r - 1))
        if (r < rings - 1) n.add(index(p, r + 1))
        n.add(index((p + 1) % protofilaments, r))
        n.add(index((p + protofilaments - 1) % protofilaments, r))
        return n.toIntArray()
    }

    /** Advance by `realDt` seconds of wall-clock time. */
    fun tick(realDt: Double) {
        if (!running) return
        val dt = realDt / slowMotion               // simulated seconds
        simTime += dt
        val dtMs = dt * 1000

        // 1. Spontaneous seeds: a few dimers enter superposition on their own.
        val seedRate = 0.03 * dtMs
        if (rng.nextDouble() < seedRate) {
            val i = rng.nextInt(count)
            if (states[i] != SUPERPOSED) { states[i] = SUPERPOSED; phase[i] = rng.nextFloat() }
        }

        // 2. Orchestration: superposed dimers recruit neighbours.
        val recruit = min(1.0, orchestration * 0.5 * dtMs)
        val newly = ArrayList<Int>()
        for (i in 0 until count) {
            if (states[i] != SUPERPOSED) continue
            for (n in neighbours(i)) {
                if (states[n] != SUPERPOSED && rng.nextDouble() < recruit) newly.add(n)
            }
        }
        for (n in newly) { states[n] = SUPERPOSED; phase[n] = rng.nextFloat() }

        // 3. Environmental decoherence, if enabled: superpositions die at rate 1/t_dec.
        if (decoherenceEnabled) {
            val p = min(1.0, dt / decoherenceTime)
            for (i in 0 until count) {
                if (states[i] == SUPERPOSED && rng.nextDouble() < p) states[i] = if (rng.nextBool()) A else B
            }
        }

        // 4. Count, accumulate action, pulse.
        superposedCount = states.count { it == SUPERPOSED }
        action += gravitationalSelfEnergy * dt
        if (superposedCount == 0) action = 0.0
        val pulse = (dt * 1000 * 0.12).toFloat()
        for (i in 0 until count) if (states[i] == SUPERPOSED) phase[i] = (phase[i] + pulse) % 1f
        flash = max(0f, flash - (realDt * 2.5).toFloat())
        if (flash == 0f && lastCollapsed.any { it }) lastCollapsed.fill(false)

        // 5. Objective reduction when ∫E_G dt ≥ ħ.
        if (action >= Physics.HBAR && superposedCount > 0) {
            val n = superposedCount
            events.add(OREvent(simTime, n, effectiveTubulins, tau))
            for (i in 0 until count) {
                lastCollapsed[i] = states[i] == SUPERPOSED
                if (states[i] == SUPERPOSED) states[i] = if (rng.nextBool()) A else B
            }
            superposedCount = 0
            action = 0.0
            flash = 1f
            if (events.size > 200) events.removeAt(0)
        }

        // 6. History sample every 0.5 simulated ms.
        if (simTime - lastSampleTime >= 0.0005) {
            history.add(HistoryPoint(historyCounter, simTime, superposedCount))
            historyCounter += 1
            lastSampleTime = simTime
            if (history.size > 400) history.removeAt(0)
        }
    }

    /**
     * Screenshot staging, debug builds only (as on iOS): `hero` runs the model for a while to fill the
     * timeline, then freezes it mid-collapse with every dimer state on screen at once.
     */
    fun stage(stage: String) {
        repeat(2400) { tick(1.0 / 30) }
        if (stage != "hero") return
        for (i in 0 until count) { lastCollapsed[i] = false; states[i] = if (rng.nextBool()) A else B }
        for (r in 0 until rings) {
            for (p in 0 until protofilaments) {
                val i = index(p, r)
                if (r in 3..12 && p != 6 && p != 7) lastCollapsed[i] = true
                if (r in 15..25 && !(r >= 23 && p >= 9)) { states[i] = SUPERPOSED; phase[i] = rng.nextFloat() }
            }
        }
        superposedCount = states.count { it == SUPERPOSED }
        action = Physics.HBAR * 0.82
        flash = 0.9f
        running = false
    }
}
