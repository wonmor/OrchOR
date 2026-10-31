package com.johnseong.orchor.ui

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.johnseong.orchor.BuildConfig

@Composable
fun AboutScreen(onClose: () -> Unit) {
    val version = "${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})"
    Page {
        ScreenHeader("00", "About", "orch-or", Bauhaus.Yellow) {
            BauhausButton("Close", Icons.Outlined.Close, compact = true, onClick = onClose)
        }
        Panel {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                BrandMark(72.dp)
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("Orch-OR Visualizer", style = jostStyle(22.sp, FontWeight.Bold))
                    Tracked("Version $version", size = 11.sp)
                }
            }
        }
        Block("What it is", Bauhaus.Ink,
            "An interactive model of the Penrose–Hameroff theory of consciousness: microtubules, tubulin superposition, and objective reduction.")
        Block("What the simulation is, and isn't", Bauhaus.Red,
            "The lattice, the growth of coherence and the collapse rule ∫E_G dt ≥ ħ follow the theory's own description, with the Diósi–Penrose timescale calibrated to Hameroff & Penrose (2014). Recruitment rates, seeding and the choice of post-collapse states are illustrative. It is a teaching model, not a physical simulation, and the theory itself is contested; see the Learn tab for both sides.")
        Block("Privacy", Bauhaus.Blue, "The app runs entirely on your device and collects no data.")
    }
}

@Composable
private fun Block(title: String, accent: Color, body: String) {
    Panel(accent = accent) {
        Text(title, style = jostStyle(22.sp, FontWeight.Bold), modifier = Modifier.semantics { heading() })
        Text(body, style = jostStyle(16.sp).copy(lineHeight = 23.sp))
    }
}
