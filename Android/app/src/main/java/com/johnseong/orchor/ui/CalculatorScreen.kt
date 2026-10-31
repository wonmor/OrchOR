package com.johnseong.orchor.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.johnseong.orchor.model.Physics
import com.johnseong.orchor.model.fmt
import com.johnseong.orchor.model.sci
import com.johnseong.orchor.model.timeString
import kotlin.math.log10
import kotlin.math.pow

/** Diósi–Penrose objective-reduction calculator, calibrated as in Hameroff & Penrose (2014). */
@Composable
fun CalculatorScreen() {
    var logN by rememberSaveable { mutableDoubleStateOf(log10(2e10)) }
    var fractionExponent by rememberSaveable { mutableDoubleStateOf(-3.0) }
    val n = 10.0.pow(logN)
    val eG = Physics.gravitationalSelfEnergy(n)
    val tau = Physics.collapseTime(n)
    val neurons = n / (Physics.TUBULINS_PER_NEURON * 10.0.pow(fractionExponent))
    Page {
        ScreenHeader("03", "Diósi–Penrose", "calculator", Bauhaus.Red)
        if (isWide()) {
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Box(Modifier.weight(1f)) { TauPanel(logN, { logN = it }, n, eG, tau) }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    TimescalePanel(tau); NeuronPanel(fractionExponent, { fractionExponent = it }, neurons)
                }
            }
        } else {
            TauPanel(logN, { logN = it }, n, eG, tau)
            TimescalePanel(tau)
            NeuronPanel(fractionExponent, { fractionExponent = it }, neurons)
        }
    }
}

@Composable
private fun TauPanel(logN: Double, setLogN: (Double) -> Unit, n: Double, eG: Double, tau: Double) {
    Panel(accent = Bauhaus.Yellow) {
        Tracked("Collapse time")
        Text("τ ≈ ħ / E_G", style = TextStyle(fontFamily = FontFamily.Serif, fontStyle = FontStyle.Italic, fontWeight = FontWeight.Bold, fontSize = 38.sp, color = Bauhaus.Ink),
            modifier = Modifier.semantics { contentDescription = "tau is approximately h-bar over E G" })
        Note("How long a superposition of N tubulins survives before objective reduction.")
        HRule()
        BauhausSlider("Tubulins in coherent superposition", logN, 6.0..13.0, Bauhaus.Yellow, { 10.0.pow(it).sci("", 1) }, setLogN)
        Column(Modifier.fillMaxWidth().background(Bauhaus.Yellow).border(Bauhaus.Rule, Bauhaus.Ink, RectangleShape).padding(14.dp)
            .semantics(mergeDescendants = true) {}) {
            Tracked("τ", color = Bauhaus.Ink)
            Text(tau.timeString, style = jostStyle(40.sp, FontWeight.Bold), maxLines = 1)
        }
        ReadoutRow { m ->
            Readout("N", n.sci("", 1), m)
            Readout("E_G", eG.sci("J", 1), m)
            Readout("Rate", if (tau.isFinite()) fmt("%.1f Hz", 1 / tau) else "—", m, marker = Bauhaus.Red)
        }
        Note("Calibration: Hameroff & Penrose (2014) estimate that ~2×10¹⁰ tubulins, each displaced by about the width of an atomic nucleus, give τ ≈ 25 ms, the period of 40 Hz gamma synchrony.")
    }
}

@Composable
private fun TimescalePanel(tau: Double) {
    Panel(accent = Bauhaus.Red) {
        SectionTitle("Timescales on a log axis", "The whole argument is about whether coherence lasts long enough")
        LogScaleBars(listOf(
            Triple("Your τ", tau, Bauhaus.Yellow),
            Triple("25 ms – 40 Hz", 0.025, Bauhaus.Ink),
            Triple("500 ms – pre-conscious", 0.5, Bauhaus.Ink),
            Triple("Hagan et al. decoherence", Physics.HAGAN_DECOHERENCE, Bauhaus.Red),
            Triple("Tegmark decoherence", Physics.TEGMARK_DECOHERENCE, Bauhaus.Red),
        ))
        Note("For Orch-OR to work, the decoherence time must exceed τ. Tegmark (2000) put decoherence at 10⁻¹³ s; Hagan, Hameroff & Tuszynski (2002) argued for 10⁻⁵ to 10⁻⁴ s with shielding by ordered water and counter-ions. Even the friendlier number is far below 25 ms, which is why the theory remains contested.")
    }
}

@Composable
private fun NeuronPanel(fractionExponent: Double, set: (Double) -> Unit, neurons: Double) {
    Panel(accent = Bauhaus.Blue) {
        SectionTitle("How many neurons?", "A neuron holds ~10⁹ tubulins; only some would participate")
        BauhausSlider("Fraction of each neuron's tubulins", fractionExponent, -5.0..0.0, Bauhaus.Blue,
            { fmt("%.3g%%", 10.0.pow(it) * 100) }, set)
        Readout("Neurons needed", neurons.sci("", 1), size = 30.sp)
        Note("With 0.1% of tubulins per neuron, 2×10¹⁰ tubulins means about 20,000 neurons: the figure Hameroff & Penrose quote for one 25 ms conscious moment.")
    }
}

/** Horizontal log-scale bar chart: flat colour bars on a 2 dp black baseline, 10⁻¹⁴ s to 10 s. */
@Composable
private fun LogScaleBars(items: List<Triple<String, Double, Color>>) {
    val lo = -14.0; val hi = 1.0
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        items.forEach { (label, v, c) ->
            Column(Modifier.semantics(mergeDescendants = true) {}, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Row {
                    Tracked(label, color = Bauhaus.Ink, size = 11.sp, modifier = Modifier.weight(1f))
                    Text(v.timeString, style = jostStyle(13.sp, FontWeight.Medium))
                }
                val x = if (v.isFinite()) ((log10(v) - lo) / (hi - lo)).coerceIn(0.0, 1.0).toFloat() else 1f
                Box(Modifier.fillMaxWidth().height(14.dp).background(Bauhaus.Soft).border(Bauhaus.Thin, Bauhaus.Ink, RectangleShape)) {
                    Box(Modifier.fillMaxWidth(x).widthIn(min = 4.dp).fillMaxHeight().background(c))
                }
            }
        }
        HRule()
        Row {
            Text("10⁻¹⁴ s", style = jostStyle(11.sp, FontWeight.Medium, Bauhaus.InkSecondary), modifier = Modifier.weight(1f))
            Text("10 s", style = jostStyle(11.sp, FontWeight.Medium, Bauhaus.InkSecondary))
        }
    }
}
