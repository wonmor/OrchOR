package com.johnseong.orchor.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Bolt
import androidx.compose.material.icons.outlined.SwapVert
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.johnseong.orchor.model.compact
import com.johnseong.orchor.model.fmt
import com.johnseong.orchor.model.timeString
import kotlin.math.*

@Composable
fun TimelineScreen(state: SimState) {
    state.frame
    val wide = isWide()
    Page {
        ScreenHeader("02", "Coherence over time", "timeline", Bauhaus.Yellow)
        ChartPanel(state)
        if (wide) {
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Box(Modifier.weight(1f)) { MomentsPanel(state) }
                Box(Modifier.width(360.dp)) { RatePanel(state) }
            }
        } else {
            RatePanel(state); MomentsPanel(state)
        }
    }
}

@Composable
private fun ChartPanel(state: SimState) {
    val sim = state.sim
    val measurer = rememberTextMeasurer()
    val labelStyle = jostStyle(11.sp, FontWeight.Medium, Bauhaus.InkSecondary)
    Panel(accent = Bauhaus.Yellow) {
        SectionTitle("Coherent superposition", "Dimers in superposition, with each objective-reduction event as a vertical red rule")
        Row(horizontalArrangement = Arrangement.spacedBy(18.dp)) {
            KeyRow(Icons.Outlined.SwapVert, Bauhaus.Yellow, "Superposed dimers")
            KeyRow(Icons.Outlined.Bolt, Bauhaus.Red, "OR event")
        }
        Canvas(Modifier.fillMaxWidth().height(if (isWide()) 360.dp else 240.dp).semantics {
            contentDescription = "Chart of superposed dimers over simulated time, ${sim.events.size} objective-reduction events so far"
        }) {
            state.frame.hashCode()
            val h = sim.history
            val left = 34.dp.toPx(); val bottom = size.height - 34.dp.toPx(); val top = 4.dp.toPx(); val right = size.width
            val w = right - left; val ht = bottom - top
            val t0 = (h.firstOrNull()?.simTime ?: 0.0) * 1000; val t1 = max(t0 + 1e-6, (h.lastOrNull()?.simTime ?: 0.001) * 1000)
            fun x(t: Double) = (left + (t - t0) / (t1 - t0) * w).toFloat()
            fun y(v: Double) = (bottom - v / sim.count * ht).toFloat()
            // grid + y labels
            for (v in listOf(0, 100, 200, 300)) {
                drawLine(Bauhaus.Hairline, Offset(left, y(v.toDouble())), Offset(right, y(v.toDouble())), 1.dp.toPx())
                val tl = measurer.measure("$v", labelStyle)
                drawText(tl, topLeft = Offset(left - tl.size.width - 6.dp.toPx(), y(v.toDouble()) - tl.size.height / 2))
            }
            // x ticks
            val span = t1 - t0
            val stepRaw = span / 5; val mag = 10.0.pow(floor(log10(max(stepRaw, 1e-9))))
            val step = listOf(1.0, 2.0, 5.0, 10.0).map { it * mag }.first { it >= stepRaw }
            var t = ceil(t0 / step) * step
            while (t <= t1) {
                drawLine(Bauhaus.Hairline, Offset(x(t), top), Offset(x(t), bottom), 1.dp.toPx())
                drawLine(Bauhaus.Ink, Offset(x(t), bottom), Offset(x(t), bottom + 6.dp.toPx()), 2.dp.toPx())
                val tl = measurer.measure(fmt("%.0f", t), labelStyle)
                drawText(tl, topLeft = Offset(x(t) - tl.size.width / 2, bottom + 8.dp.toPx()))
                t += step
            }
            if (h.size >= 2) {
                val area = Path().apply {
                    moveTo(x(h.first().simTime * 1000), bottom)
                    h.forEach { lineTo(x(it.simTime * 1000), y(it.superposed.toDouble())) }
                    lineTo(x(h.last().simTime * 1000), bottom); close()
                }
                drawPath(area, Bauhaus.Yellow.copy(alpha = 0.55f))
                val line = Path().apply {
                    h.forEachIndexed { i, p -> if (i == 0) moveTo(x(p.simTime * 1000), y(p.superposed.toDouble())) else lineTo(x(p.simTime * 1000), y(p.superposed.toDouble())) }
                }
                drawPath(line, Bauhaus.Ink, style = Stroke(2.dp.toPx()))
            }
            sim.events.filter { e -> h.firstOrNull()?.let { e.simTime >= it.simTime } ?: false }.forEach { e ->
                drawLine(Bauhaus.Red, Offset(x(e.simTime * 1000), top), Offset(x(e.simTime * 1000), bottom), 2.dp.toPx())
            }
            drawLine(Bauhaus.Ink, Offset(left, bottom), Offset(right, bottom), 2.dp.toPx())
            drawLine(Bauhaus.Ink, Offset(left, top), Offset(left, bottom), 2.dp.toPx())
            val xl = measurer.measure(Bauhaus.caps("Simulated time (ms)"), jostStyle(11.sp, FontWeight.SemiBold, Bauhaus.InkSecondary, 1.6.sp))
            drawText(xl, topLeft = Offset(left, size.height - xl.size.height.toFloat()))
        }
    }
}

@Composable
private fun RatePanel(state: SimState) {
    val sim = state.sim
    Panel(accent = Bauhaus.Red) {
        Tracked("Current event rate")
        Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(sim.eventFrequencyHz?.let { fmt("%.0f", it) } ?: "—", style = jostStyle(72.sp, FontWeight.Bold).copy(lineHeight = 76.sp))
            Text("Hz", style = jostStyle(22.sp, FontWeight.Bold, Bauhaus.InkSecondary), modifier = Modifier.padding(bottom = 12.dp))
        }
        HRule()
        Note("Hameroff & Penrose associate conscious moments with gamma synchrony, roughly 40 Hz: one event every 25 ms.")
    }
}

@Composable
private fun MomentsPanel(state: SimState) {
    val sim = state.sim
    Panel(accent = Bauhaus.Red) {
        SectionTitle("Recent moments", "Each OR event is, in the theory, a discrete moment of experience")
        if (sim.events.isEmpty()) {
            Note("No events yet. Let the simulation run on the Microtubule tab.")
        } else {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row { listOf("t", "Dimers", "Tubulins").forEach { Tracked(it, size = 11.sp, modifier = Modifier.weight(1f)) }
                    Tracked("τ", size = 11.sp) }
                HRule()
                sim.events.takeLast(8).reversed().forEach { e ->
                    val st = jostStyle(14.sp, FontWeight.Medium)
                    Row(Modifier.semantics(mergeDescendants = true) {}) {
                        Text(fmt("%.1f ms", e.simTime * 1000), style = st, modifier = Modifier.weight(1f))
                        Text("${e.tubulins}", style = st, modifier = Modifier.weight(1f))
                        Text(e.effectiveTubulins.compact, style = st, modifier = Modifier.weight(1f))
                        Text(e.tau.timeString, style = st.copy(fontWeight = FontWeight.SemiBold))
                    }
                    HRule(Bauhaus.Hairline, 1.dp)
                }
            }
        }
    }
}
