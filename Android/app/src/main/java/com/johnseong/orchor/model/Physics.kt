package com.johnseong.orchor.model

import java.util.Locale
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.log10
import kotlin.math.pow

/** Constants and formulas used throughout the app, as in the iOS `Physics`. Sources are listed in Learn. */
object Physics {
    /** Reduced Planck constant, J s. */
    const val HBAR = 1.054_571_817e-34
    /**
     * Hameroff & Penrose (2014) calibrate the Diósi–Penrose criterion so that about 2×10¹⁰ tubulins in
     * coherent superposition self-collapse in 25 ms (the 40 Hz gamma "conscious moment").
     */
    const val CALIBRATION_TUBULINS = 2.0e10
    const val CALIBRATION_TAU = 0.025
    /** Gravitational self-energy contributed by one tubulin in superposition, ≈ 2.1e-43 J. */
    val energyPerTubulin: Double = HBAR / (CALIBRATION_TAU * CALIBRATION_TUBULINS)
    /** Tubulins per neuron, order of magnitude. */
    const val TUBULINS_PER_NEURON = 1.0e9
    /** Decoherence estimates for microtubule superpositions, seconds. */
    const val TEGMARK_DECOHERENCE = 1e-13
    const val HAGAN_DECOHERENCE = 1e-4

    fun gravitationalSelfEnergy(tubulins: Double): Double = tubulins * energyPerTubulin

    /** τ ≈ ħ / E_G */
    fun collapseTime(tubulins: Double): Double {
        val e = gravitationalSelfEnergy(tubulins)
        return if (e > 0) HBAR / e else Double.POSITIVE_INFINITY
    }
}

private fun f(format: String, vararg args: Any): String = String.format(Locale.US, format, *args)

/** "2.1×10⁻⁴³ J" style with a unit, or "∞". */
fun Double.sci(unit: String = "", digits: Int = 2): String {
    if (!isFinite()) return "∞"
    if (this == 0.0) return "0 $unit"
    val exp = floor(log10(abs(this))).toInt()
    val mant = this / 10.0.pow(exp.toDouble())
    val m = f("%.${digits}f", mant)
    return "$m×10${exp.toString().superscript()} $unit".trim()
}

/** Human time: 25 ms, 1.3 s, 100 fs… */
val Double.timeString: String
    get() {
        if (!isFinite()) return "never"
        val a = abs(this)
        return when {
            a >= 1 -> f("%.2f s", this)
            a >= 1e-3 -> f("%.1f ms", this * 1e3)
            a >= 1e-6 -> f("%.1f µs", this * 1e6)
            a >= 1e-9 -> f("%.1f ns", this * 1e9)
            a >= 1e-12 -> f("%.1f ps", this * 1e12)
            else -> f("%.1f fs", this * 1e15)
        }
    }

val Double.compact: String
    get() = when {
        this >= 1e9 -> f("%.1f B", this / 1e9)
        this >= 1e6 -> f("%.1f M", this / 1e6)
        this >= 1e3 -> f("%.1f k", this / 1e3)
        else -> f("%.0f", this)
    }

/** "-34" → "⁻³⁴", for integer exponents in readouts. */
fun String.superscript(): String {
    val table = mapOf('0' to '⁰', '1' to '¹', '2' to '²', '3' to '³', '4' to '⁴', '5' to '⁵', '6' to '⁶',
        '7' to '⁷', '8' to '⁸', '9' to '⁹', '-' to '⁻', '+' to '⁺')
    return map { table[it] ?: it }.joinToString("")
}

fun fmt(format: String, vararg args: Any): String = f(format, *args)
