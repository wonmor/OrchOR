package com.johnseong.orchor.model

/**
 * SplitMix64 (Steele, Lea & Flood 2014), identical to the iOS `SplitMix64` so a seeded run draws the
 * same sequence on both platforms. Unsigned arithmetic wraps exactly like Swift's `&+` and `&*`.
 */
class SplitMix64(seed: ULong) {
    var state: ULong = seed
        private set

    fun next(): ULong {
        state += 0x9E3779B97F4A7C15uL
        var z = state
        z = (z xor (z shr 30)) * 0xBF58476D1CE4E5B9uL
        z = (z xor (z shr 27)) * 0x94D049BB133111EBuL
        return z xor (z shr 31)
    }

    /** Uniform in [0, 1) with 53 random bits. */
    fun nextDouble(): Double = (next() shr 11).toDouble() * TWO_POW_MINUS_53

    /** Uniform in [0, 1) with 24 random bits. */
    fun nextFloat(): Float = (next() shr 40).toFloat() * TWO_POW_MINUS_24

    /** Uniform in 0 until n. */
    fun nextInt(n: Int): Int = (nextDouble() * n.toDouble()).toInt()

    fun nextBool(): Boolean = (next() shr 63) == 1uL

    private companion object {
        const val TWO_POW_MINUS_53 = 1.0 / 9007199254740992.0
        const val TWO_POW_MINUS_24 = 1.0f / 16777216.0f
    }
}
