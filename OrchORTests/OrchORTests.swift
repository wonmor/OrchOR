import XCTest
@testable import OrchOR

/// Golden values for the model. The Android port (Android/app/src/test/.../ParityTest.kt) asserts the
/// same numbers, so the two apps are checked against each other on fixed inputs.
@MainActor
final class OrchORTests: XCTestCase {
    func testSplitMix64MatchesReference() {
        var r = SplitMix64(seed: 0)
        XCTAssertEqual(r.next(), 0xE220_A839_7B1D_CDAF)   // published SplitMix64 vector
        XCTAssertEqual(r.next(), 0x6E78_9E6A_A1B9_65F4)
        XCTAssertEqual(r.next(), 0x06C4_5D18_8009_454F)
        r = SplitMix64(seed: 42)
        XCTAssertEqual([r.next(), r.next(), r.next()], [13679457532755275413, 2949826092126892291, 5139283748462763858])
        XCTAssertEqual(r.nextDouble(), 0.34419071652363753)
        XCTAssertEqual(r.nextFloat(), 0.038030148, accuracy: 1e-9)
        XCTAssertEqual(r.nextInt(390), 338)
        XCTAssertFalse(r.nextBool())
    }

    func testPhysicsCalibration() {
        XCTAssertEqual(Physics.energyPerTubulin, 2.109143634e-43, accuracy: 1e-52)
        XCTAssertEqual(Physics.collapseTime(tubulins: 2e10), 0.025, accuracy: 1e-15)
        XCTAssertEqual(Physics.collapseTime(tubulins: 1e6), 500, accuracy: 1e-9)
        XCTAssertEqual(Physics.collapseTime(tubulins: 0), .infinity)
    }

    func testFormatting() {
        XCTAssertEqual(Physics.energyPerTubulin.sci("J", digits: 1), "2.1×10⁻⁴³ J")
        XCTAssertEqual(2e10.sci("", digits: 1), "2.0×10¹⁰")
        XCTAssertEqual(0.0.sci("J"), "0 J")
        XCTAssertEqual(Double.infinity.sci(), "∞")
        XCTAssertEqual([0.025, 1e-13, 1e-4, 2.5, 3.2e-8].map(\.timeString), ["25.0 ms", "100.0 fs", "100.0 µs", "2.50 s", "32.0 ns"])
        XCTAssertEqual([2.3e10, 4.5e6, 1234, 12].map(\.compact), ["23.0 B", "4.5 M", "1.2 k", "12"])
    }

    private func run(seed: UInt64, ticks: Int, _ configure: (OrchORSimulation) -> Void = { _ in }) -> OrchORSimulation {
        let sim = OrchORSimulation(seed: seed)
        configure(sim)
        for _ in 0 ..< ticks { sim.tick(realDt: 1.0 / 30) }
        return sim
    }

    private func checksum(_ sim: OrchORSimulation) -> Int {
        var c = 0
        for (i, s) in sim.states.enumerated() { c = (c &* 31 &+ Int(s.rawValue) &+ i) % 1_000_000_007 }
        return c
    }

    func testDefaultRunSeed7() {
        let sim = run(seed: 7, ticks: 3000)
        XCTAssertEqual(sim.superposedCount, 189)
        XCTAssertEqual(sim.events.count, 33)
        XCTAssertEqual(sim.history.count, 400)
        XCTAssertEqual(checksum(sim), 569631294)
        XCTAssertEqual(sim.action, 1.5169038637594914e-35, accuracy: 1e-48)
        XCTAssertEqual(sim.simTime, 2.5, accuracy: 1e-12)
        XCTAssertEqual(sim.events.prefix(5).map(\.tubulins), [374, 383, 390, 390, 390])
        XCTAssertEqual(sim.events[0].simTime, 0.065, accuracy: 1e-12)
        XCTAssertEqual(sim.events[1].simTime, 0.14333333333333345, accuracy: 1e-12)
    }

    func testDecoherenceAtHaganStopsEveryEvent() {
        let sim = run(seed: 11, ticks: 1500) { s in
            s.decoherenceEnabled = true; s.decoherenceExponent = -4
            s.orchestration = 0.9; s.representationExponent = 8.3; s.slowMotion = 20
        }
        XCTAssertEqual(sim.events.count, 0)
        XCTAssertEqual(sim.superposedCount, 0)
        XCTAssertEqual(checksum(sim), 831832460)
    }

    func testWeakOrchestrationSeed2026() {
        let sim = run(seed: 2026, ticks: 2000) { s in
            s.orchestration = 0.25; s.representationExponent = 6.5; s.slowMotion = 120
        }
        XCTAssertEqual(sim.events.count, 1)
        XCTAssertEqual(sim.events.first?.tubulins, 390)
        XCTAssertEqual(sim.events.first?.simTime ?? 0, 0.45916666666665262, accuracy: 1e-12)
        XCTAssertEqual(checksum(sim), 678951238)
    }
}
