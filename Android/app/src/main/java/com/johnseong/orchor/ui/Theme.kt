package com.johnseong.orchor.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.johnseong.orchor.R

/**
 * The Bauhaus design language shared with the iOS app and John's other apps: white ground, black ink,
 * Jost geometric type, thick black rules, square edges, and the three primaries with fixed meanings:
 * blue for what you control, yellow for coherent superposition, red for objective reduction and the
 * decoherence that destroys superposition. Classical tubulin states are black (A) and grey (B).
 */
object Bauhaus {
    val Ground = Color.White
    val Ink = Color.Black
    val InkSecondary = Color(0xFF3C3C3C)
    val Soft = Color(0xFFF2F2F2)
    val Hairline = Color(0xFFCFCFCF)
    val Blue = Color(0xFF0F3FA8)
    val Yellow = Color(0xFFF2C230)
    val Red = Color(0xFFD62828)
    val RedInk = Color(0xFFA61B1B)
    val StateA = Color.Black
    val StateB = Color(0xFF8A8A8A)

    val Thin = 1.dp
    val Rule = 2.dp
    val Thick = 4.dp
    val Heavy = 8.dp
    val TapTarget = 48.dp
    val MaxContentWidth = 1180.dp

    /** Ink that reads on a given field. */
    fun onField(c: Color): Color = if (c == Yellow || c == Ground || c == Soft) Ink else Ground

    /** Uppercase for tracked labels, leaving maths symbols and Greek alone (τ, ħ, µ, ∫). */
    fun caps(s: String): String = s.map { if ("τħµ∫".contains(it)) it.toString() else it.uppercase() }.joinToString("")
}

@OptIn(androidx.compose.ui.text.ExperimentalTextApi::class)
private fun jost(weight: Int) = Font(
    R.font.jost, FontWeight(weight),
    variationSettings = FontVariation.Settings(FontVariation.weight(weight)),
)

/** Jost (SIL Open Font License), bundled as a variable font. */
val Jost = FontFamily(jost(400), jost(500), jost(600), jost(700))
