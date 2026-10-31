package com.johnseong.orchor

import android.content.pm.ApplicationInfo
import android.graphics.Color as AColor
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.Functions
import androidx.compose.material.icons.outlined.MonitorHeart
import androidx.compose.material.icons.outlined.ViewInAr
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.johnseong.orchor.ui.*

class MainActivity : ComponentActivity() {
    private val state = SimState()

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.light(AColor.WHITE, AColor.WHITE),
            navigationBarStyle = SystemBarStyle.light(AColor.WHITE, AColor.WHITE),
        )
        super.onCreate(savedInstanceState)
        // Screenshot staging for debug builds only, as on iOS: `--es stage hero --ei tab N --ez about true`.
        val debuggable = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        val startTab = if (debuggable) intent.getIntExtra("tab", 0).coerceIn(0, 3) else 0
        if (debuggable && savedInstanceState == null) intent.getStringExtra("stage")?.let { s -> state.update { stage(s) } }
        val startAbout = debuggable && intent.getBooleanExtra("about", false)
        setContent { App(state, startTab, startAbout) }
    }
}

private data class TabItem(val title: String, val icon: ImageVector)
private val tabs = listOf(
    TabItem("Microtubule", Icons.Outlined.ViewInAr),
    TabItem("Timeline", Icons.Outlined.MonitorHeart),
    TabItem("Calculator", Icons.Outlined.Functions),
    TabItem("Learn", Icons.AutoMirrored.Outlined.MenuBook),
)

@Composable
internal fun App(state: SimState, startTab: Int, startAbout: Boolean) {
    var tab by rememberSaveable { mutableIntStateOf(startTab) }
    var about by rememberSaveable { mutableStateOf(startAbout) }
    var spin by remember { mutableFloatStateOf(0f) }
    // Drive the simulation from the frame clock while the app is in the foreground.
    LaunchedEffect(Unit) {
        var last = 0L
        while (true) {
            withFrameNanos { now ->
                if (last != 0L) {
                    val dt = ((now - last) / 1e9).coerceAtMost(0.1)
                    state.tick(dt)
                    if (state.sim.running) spin += (dt * 2 * Math.PI / 40).toFloat()   // one turn per 40 s
                }
                last = now
            }
        }
    }
    BackHandler(enabled = about) { about = false }
    Column(Modifier.fillMaxSize().background(Bauhaus.Ground).safeDrawingPadding()) {
        Box(Modifier.weight(1f)) {
            if (about) AboutScreen { about = false }
            else when (tab) {
                0 -> MicrotubuleScreen(state, spin) { about = true }
                1 -> TimelineScreen(state)
                2 -> CalculatorScreen()
                else -> LearnScreen()
            }
        }
        if (!about) TabBar(tab) { tab = it }
    }
}

/** White bar under a 4 dp black rule, four columns split by 2 dp rules; the selected column is blue. */
@Composable
private fun TabBar(selection: Int, onSelect: (Int) -> Unit) {
    Column {
        HRule(height = Bauhaus.Thick)
        Row(Modifier.height(IntrinsicSize.Min)) {
            tabs.forEachIndexed { i, item ->
                if (i > 0) VRule()
                val on = selection == i
                val fg = if (on) Bauhaus.Ground else Bauhaus.Ink
                Column(Modifier.weight(1f).background(if (on) Bauhaus.Blue else Bauhaus.Ground)
                    .clickable(role = Role.Tab) { onSelect(i) }.semantics { selected = on }
                    .padding(vertical = 10.dp), horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Icon(item.icon, contentDescription = null, tint = fg, modifier = Modifier.size(24.dp))
                    Tracked(item.title, color = fg, size = 11.sp)
                }
            }
        }
    }
}
