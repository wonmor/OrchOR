package com.johnseong.orchor.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.johnseong.orchor.model.OrchORSimulation
import com.johnseong.orchor.model.compact
import com.johnseong.orchor.model.fmt
import com.johnseong.orchor.model.sci
import com.johnseong.orchor.model.timeString
import kotlin.math.*

@Composable
fun MicrotubuleScreen(state: SimState, spin: Float, onAbout: () -> Unit) {
    val f = state.frame   // read so the screen recomposes every tick
    val sim = state.sim
    val wide = isWide()
    Page {
        ScreenHeader("01", "Orch-OR lattice", "microtubule", Bauhaus.Blue) {
            BauhausButton("About", Icons.Outlined.Info, compact = true, onClick = onAbout)
        }
        if (wide) {
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                LatticeBlock(sim, f, spin, 780.dp, Modifier.weight(1f))
                Column(Modifier.width(420.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Readouts(sim); Controls(state)
                }
            }
        } else {
            LatticeBlock(sim, f, spin, 380.dp, Modifier.fillMaxWidth())
            Readouts(sim)
            Controls(state)
        }
    }
}

@Composable
private fun LatticeBlock(sim: OrchORSimulation, frame: Long, spin: Float, height: Dp, modifier: Modifier) {
    var userYaw by remember { mutableFloatStateOf(0f) }
    var zoom by remember { mutableFloatStateOf(1f) }
    Box(modifier.height(height).border(Bauhaus.Rule, Bauhaus.Ink, RectangleShape)) {
        Canvas(Modifier.fillMaxSize()
            .pointerInput(Unit) {
                detectTransformGestures { _, pan, z, _ -> userYaw += pan.x / 150f; zoom = (zoom * z).coerceIn(0.6f, 2.5f) }
            }
            .semantics { contentDescription = "3D microtubule lattice, ${sim.superposedCount} of ${sim.count} dimers in superposition" }
        ) {
            frame.hashCode()
            drawLattice(sim, spin + userYaw, zoom)
            if (sim.flash > 0f) drawRect(Bauhaus.Red.copy(alpha = sim.flash * 0.08f))
        }
        Column(Modifier.padding(12.dp).background(Bauhaus.Ground.copy(alpha = 0.92f)).border(Bauhaus.Rule, Bauhaus.Ink, RectangleShape)
            .padding(10.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            KeyRow(Icons.Outlined.ArrowUpward, Bauhaus.StateA, "Tubulin state A")
            KeyRow(Icons.Outlined.ArrowDownward, Bauhaus.StateB, "Tubulin state B")
            KeyRow(Icons.Outlined.SwapVert, Bauhaus.Yellow, "Superposition")
            KeyRow(Icons.Outlined.Bolt, Bauhaus.Red, "Objective reduction")
        }
        if (sim.flash > 0.05f) {
            Row(Modifier.align(Alignment.BottomEnd).background(Bauhaus.Red).border(Bauhaus.Rule, Bauhaus.Ink, RectangleShape)
                .padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(Icons.Outlined.Bolt, null, tint = Bauhaus.Ground, modifier = Modifier.size(16.dp))
                Tracked("Objective reduction", color = Bauhaus.Ground, size = 13.sp)
            }
        }
    }
}

private val colorA = Color(0xFF121212)
private val colorB = Color(0xFF8A8A8A)
private val lumen = Color(0xFFE6E6E6)

/**
 * Software 3D of the same lattice the iOS app draws with SceneKit: 13 protofilaments on a radius-1
 * cylinder, a 3-start helical rise, the tube tilted onto a diagonal and spinning about its own axis.
 * Dimers are depth-sorted and shaded with a neutral key light plus ambient fill.
 */
private fun androidx.compose.ui.graphics.drawscope.DrawScope.drawLattice(sim: OrchORSimulation, yaw: Float, zoom: Float) {
    val proto = sim.protofilaments; val rings = sim.rings
    val radius = 1.0; val dz = 0.26
    val tilt = -0.42; val pitch = 0.18          // tube lean on screen, camera elevation
    val camDist = 13.5
    val scale = min(size.width, size.height * 0.55f) / 5.2f * zoom
    val cx = size.width / 2; val cy = size.height / 2
    val light = doubleArrayOf(-0.45, 0.55, 0.70).let { v -> val n = sqrt(v.sumOf { it * it }); v.map { it / n } }

    class P(val x: Float, val y: Float, val depth: Double, val r: Float, val shade: Float, val i: Int)
    fun project(px: Double, py: Double, pz: Double): Triple<Double, Double, Double> {
        // elevation about x
        val y1 = py * cos(pitch) - pz * sin(pitch); val z1 = py * sin(pitch) + pz * cos(pitch)
        // lean in the screen plane
        val x2 = px * cos(tilt) - y1 * sin(tilt); val y2 = px * sin(tilt) + y1 * cos(tilt)
        return Triple(x2, y2, z1)
    }
    val pts = ArrayList<P>(proto * rings)
    for (r in 0 until rings) for (p in 0 until proto) {
        val a = p.toDouble() / proto * 2 * PI + yaw
        val z = r * dz + p * (3 * dz / proto) - rings * dz / 2
        val (x, y, d) = project(radius * cos(a), z, radius * sin(a))
        val persp = camDist / (camDist - d)
        val nx = cos(a); val nz = sin(a)
        val (lx, ly, lz) = project(nx, 0.0, nz)
        val lam = max(0.0, lx * light[0] + ly * light[1] + lz * light[2])
        pts += P((cx + x * scale * persp).toFloat(), (cy - y * scale * persp).toFloat(), d, (0.11 * scale * persp).toFloat(),
            (0.45 + 0.55 * lam).toFloat(), sim.index(p, r))
    }
    // Lumen: the pale core between the back and front halves.
    val half = rings * dz / 2 + 0.15
    val corners = listOf(Pair(-0.8, -half), Pair(0.8, -half), Pair(0.8, half), Pair(-0.8, half)).map { (x, y) ->
        val (sx, sy, _) = project(x, y, 0.0); Offset((cx + sx * scale).toFloat(), (cy - sy * scale).toFloat())
    }
    val sorted = pts.sortedBy { it.depth }
    var lumenDrawn = false
    for (pt in sorted) {
        if (!lumenDrawn && pt.depth >= 0) {
            drawPath(Path().apply { moveTo(corners[0].x, corners[0].y); corners.drop(1).forEach { lineTo(it.x, it.y) }; close() }, lumen)
            lumenDrawn = true
        }
        val i = pt.i
        val base = when (sim.states[i]) {
            OrchORSimulation.SUPERPOSED -> {
                val k = 0.5 + 0.5 * sin(sim.phase[i] * 2 * PI)
                lerp(Bauhaus.Yellow, Color.White, (0.05 + 0.15 * k).toFloat())
            }
            else -> if (sim.lastCollapsed[i] && sim.flash > 0f) Bauhaus.Red
                    else if (sim.states[i] == OrchORSimulation.A) colorA else colorB
        }
        val shaded = lerp(Color.Black, base, pt.shade.coerceIn(0f, 1f)).let { if (sim.states[i] == OrchORSimulation.SUPERPOSED) lerp(it, base, 0.4f) else it }
        drawCircle(shaded, pt.r, Offset(pt.x, pt.y))
    }
}

@Composable
private fun Readouts(sim: OrchORSimulation) {
    Panel(accent = Bauhaus.Yellow) {
        ReadoutRow { m ->
            Readout("Superposed", "${sim.superposedCount}/${sim.count}", m, marker = Bauhaus.Yellow)
            Readout("Represents", sim.effectiveTubulins.compact, m)
            Readout("E_G", sim.gravitationalSelfEnergy.sci("J", 1), m)
        }
        HRule()
        ReadoutRow { m ->
            Readout("τ = ħ/E_G", sim.tau.timeString, m, marker = Bauhaus.Yellow)
            Readout("OR events", "${sim.events.size}", m)
            Readout("Event rate", sim.eventFrequencyHz?.let { fmt("%.0f Hz", it) } ?: "—", m, marker = Bauhaus.Red)
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Tracked("∫E_G dt → ħ", color = Bauhaus.Ink, modifier = Modifier.weight(1f))
            Text(fmt("%.0f%%", sim.progressToCollapse * 100), style = jostStyle(15.sp, FontWeight.Medium))
        }
        val p = sim.progressToCollapse.toFloat()
        Box(Modifier.fillMaxWidth().height(16.dp).background(Bauhaus.Soft).border(Bauhaus.Rule, Bauhaus.Ink, RectangleShape)) {
            Box(Modifier.fillMaxWidth(p).fillMaxHeight().background(if (p >= 0.999f || sim.flash > 0.05f) Bauhaus.Red else Bauhaus.Yellow))
        }
        Note("Superposition grows by orchestration, gravitational self-energy accumulates, and at ħ the set self-collapses: one 'moment'. Simulation runs ${sim.slowMotion.toInt()}× slower than real time.")
    }
}

@Composable
private fun Controls(state: SimState) {
    val sim = state.sim
    Panel(accent = Bauhaus.Blue) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            BauhausButton(if (sim.running) "Pause" else "Run", if (sim.running) Icons.Outlined.Pause else Icons.Outlined.PlayArrow,
                fill = Bauhaus.Blue) { state.update { running = !running } }
            BauhausButton("Reset", Icons.Outlined.Refresh) { state.update { reset() } }
        }
        BauhausSlider("Orchestration (MAP coupling)", sim.orchestration, 0.0..1.0, Bauhaus.Yellow, { fmt("%.2f", it) }) { v -> state.update { orchestration = v } }
        BauhausSlider("Each displayed dimer stands for", sim.representationExponent, 5.0..9.0, Bauhaus.Blue, { 10.0.pow(it).sci("", 1) }) { v -> state.update { representationExponent = v } }
        BauhausSlider("Slow motion", sim.slowMotion, 1.0..200.0, Bauhaus.Ink, { "${it.toInt()}×" }) { v -> state.update { slowMotion = v } }
        HRule()
        BauhausToggle(sim.decoherenceEnabled, { v -> state.update { decoherenceEnabled = v } }) {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Tracked("Environmental decoherence", color = Bauhaus.Ink)
                Note("Off = Orch-OR's assumption that microtubules are shielded")
            }
        }
        if (sim.decoherenceEnabled) {
            BauhausSlider("Decoherence time", sim.decoherenceExponent, -13.0..0.0, Bauhaus.Red, { 10.0.pow(it).timeString }) { v -> state.update { decoherenceExponent = v } }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                BauhausButton("Tegmark 2000 – ", compact = true, suffix = "10⁻¹³ s") { state.update { decoherenceExponent = -13.0 } }
                BauhausButton("Hagan 2002 – ", compact = true, suffix = "10⁻⁴ s") { state.update { decoherenceExponent = -4.0 } }
            }
        }
    }
}
