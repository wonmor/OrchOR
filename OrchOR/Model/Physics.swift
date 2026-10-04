import Foundation

/// Constants and formulas used throughout the app. Sources are listed in LearnView.
enum Physics {
    /// Reduced Planck constant, J·s.
    static let hbar = 1.054_571_817e-34
    /// Hameroff & Penrose (2014) calibrate the Diósi–Penrose criterion so that about 2×10¹⁰ tubulins in
    /// coherent superposition self-collapse in 25 ms (the 40 Hz gamma "conscious moment").
    static let calibrationTubulins = 2.0e10
    static let calibrationTau = 0.025
    /// Gravitational self-energy contributed by one tubulin in superposition, derived from the calibration.
    static let energyPerTubulin = hbar / (calibrationTau * calibrationTubulins)   // ≈ 2.1e-43 J
    /// Tubulins per neuron, order of magnitude.
    static let tubulinsPerNeuron = 1.0e9
    /// Decoherence estimates for microtubule superpositions, seconds.
    static let tegmarkDecoherence = 1e-13
    static let haganDecoherence = 1e-4

    static func gravitationalSelfEnergy(tubulins n: Double) -> Double { n * energyPerTubulin }
    /// τ ≈ ħ / E_G
    static func collapseTime(tubulins n: Double) -> Double {
        let e = gravitationalSelfEnergy(tubulins: n)
        return e > 0 ? hbar / e : .infinity
    }
}

extension Double {
    /// "2.1e-43" style with a unit, or "∞".
    func sci(_ unit: String = "", digits: Int = 2) -> String {
        if !isFinite { return "∞" }
        if self == 0 { return "0 \(unit)" }
        let exp = Int(floor(log10(abs(self))))
        let mant = self / pow(10, Double(exp))
        return String(format: "%.\(digits)f×10^%d %@", mant, exp, unit).trimmingCharacters(in: .whitespaces)
    }

    /// Human time: 25 ms, 1.3 s, 100 fs…
    var timeString: String {
        if !isFinite { return "never" }
        let a = abs(self)
        if a >= 1 { return String(format: "%.2f s", self) }
        if a >= 1e-3 { return String(format: "%.1f ms", self * 1e3) }
        if a >= 1e-6 { return String(format: "%.1f µs", self * 1e6) }
        if a >= 1e-9 { return String(format: "%.1f ns", self * 1e9) }
        if a >= 1e-12 { return String(format: "%.1f ps", self * 1e12) }
        return String(format: "%.1f fs", self * 1e15)
    }

    var compact: String {
        if self >= 1e9 { return String(format: "%.1f B", self / 1e9) }
        if self >= 1e6 { return String(format: "%.1f M", self / 1e6) }
        if self >= 1e3 { return String(format: "%.1f k", self / 1e3) }
        return String(format: "%.0f", self)
    }
}
