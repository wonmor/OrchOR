package com.johnseong.orchor

import com.johnseong.orchor.model.OrchORSimulation
import com.johnseong.orchor.model.Physics
import com.johnseong.orchor.model.SplitMix64
import com.johnseong.orchor.model.compact
import com.johnseong.orchor.model.sci
import com.johnseong.orchor.model.timeString
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

/**
 * Golden values produced by the iOS model (OrchOR/Model, see OrchORTests/OrchORTests.swift, which asserts
 * the same numbers). Matching them shows the Kotlin port draws the same random sequence and applies the
 * same physics in the same order.
 */
class ParityTest {
    @Test fun splitMix64MatchesIos() {
        var r = SplitMix64(0uL)
        assertEquals(0xE220A8397B1DCDAFuL, r.next())   // published SplitMix64 vector
        assertEquals(0x6E789E6AA1B965F4uL, r.next())
        assertEquals(0x06C45D188009454FuL, r.next())
        r = SplitMix64(42uL)
        assertEquals(listOf(13679457532755275413uL, 2949826092126892291uL, 5139283748462763858uL), listOf(r.next(), r.next(), r.next()))
        assertEquals(0.34419071652363753, r.nextDouble(), 0.0)
        assertEquals(0.038030148f, r.nextFloat(), 1e-9f)
        assertEquals(338, r.nextInt(390))
        assertFalse(r.nextBool())
    }

    @Test fun physicsCalibration() {
        assertEquals(2.109143634e-43, Physics.energyPerTubulin, 1e-52)
        assertEquals(0.025, Physics.collapseTime(2e10), 1e-15)
        assertEquals(500.0, Physics.collapseTime(1e6), 1e-9)
        assertEquals(Double.POSITIVE_INFINITY, Physics.collapseTime(0.0), 0.0)
    }

    @Test fun formatting() {
        assertEquals("2.1×10⁻⁴³ J", Physics.energyPerTubulin.sci("J", 1))
        assertEquals("2.0×10¹⁰", 2e10.sci("", 1))
        assertEquals("0 J", 0.0.sci("J"))
        assertEquals("∞", Double.POSITIVE_INFINITY.sci())
        assertEquals(listOf("25.0 ms", "100.0 fs", "100.0 µs", "2.50 s", "32.0 ns"),
            listOf(0.025, 1e-13, 1e-4, 2.5, 3.2e-8).map { it.timeString })
        assertEquals(listOf("23.0 B", "4.5 M", "1.2 k", "12"), listOf(2.3e10, 4.5e6, 1234.0, 12.0).map { it.compact })
    }

    private fun run(seed: ULong, ticks: Int, configure: (OrchORSimulation) -> Unit = {}): OrchORSimulation {
        val sim = OrchORSimulation(seed)
        configure(sim)
        repeat(ticks) { sim.tick(1.0 / 30) }
        return sim
    }

    /** Same rolling hash as the Swift test: (c * 31 + state + i) mod 1e9+7. */
    private fun checksum(sim: OrchORSimulation): Long {
        var c = 0L
        sim.states.forEachIndexed { i, s -> c = (c * 31 + s + i) % 1_000_000_007L }
        return c
    }

    @Test fun defaultRunSeed7() {
        val sim = run(7uL, 3000)
        assertEquals(189, sim.superposedCount)
        assertEquals(33, sim.events.size)
        assertEquals(400, sim.history.size)
        assertEquals(569631294L, checksum(sim))
        assertEquals(1.5169038637594914e-35, sim.action, 1e-48)
        assertEquals(2.5, sim.simTime, 1e-12)
        assertEquals(listOf(374, 383, 390, 390, 390), sim.events.take(5).map { it.tubulins })
        assertEquals(0.065, sim.events[0].simTime, 1e-12)
        assertEquals(0.14333333333333345, sim.events[1].simTime, 1e-12)
    }

    @Test fun decoherenceAtHaganStopsEveryEvent() {
        val sim = run(11uL, 1500) { s ->
            s.decoherenceEnabled = true; s.decoherenceExponent = -4.0
            s.orchestration = 0.9; s.representationExponent = 8.3; s.slowMotion = 20.0
        }
        assertEquals(0, sim.events.size)
        assertEquals(0, sim.superposedCount)
        assertEquals(831832460L, checksum(sim))
    }

    @Test fun weakOrchestrationSeed2026() {
        val sim = run(2026uL, 2000) { s ->
            s.orchestration = 0.25; s.representationExponent = 6.5; s.slowMotion = 120.0
        }
        assertEquals(1, sim.events.size)
        assertEquals(390, sim.events.first().tubulins)
        assertEquals(0.45916666666665262, sim.events.first().simTime, 1e-12)
        assertEquals(678951238L, checksum(sim))
    }
}
