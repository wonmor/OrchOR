package com.johnseong.orchor.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

fun jostStyle(size: TextUnit, weight: FontWeight = FontWeight.Normal, color: Color = Bauhaus.Ink, tracking: TextUnit = 0.sp) =
    TextStyle(fontFamily = Jost, fontSize = size, fontWeight = weight, color = color, letterSpacing = tracking,
        fontFeatureSettings = "tnum")

/** True when the screen is wide enough for the two-column iPad-style layout. */
@Composable
fun isWide(): Boolean = LocalConfiguration.current.screenWidthDp >= 600

/** Uppercase, tightly tracked label. */
@Composable
fun Tracked(text: String, color: Color = Bauhaus.InkSecondary, size: TextUnit = 12.sp, modifier: Modifier = Modifier) {
    Text(Bauhaus.caps(text), modifier = modifier, style = jostStyle(size, FontWeight.SemiBold, color, 1.6.sp))
}

@Composable
fun Note(text: String, modifier: Modifier = Modifier) {
    Text(text, modifier = modifier, style = jostStyle(14.sp, color = Bauhaus.InkSecondary).copy(lineHeight = 19.sp))
}

@Composable
fun HRule(color: Color = Bauhaus.Ink, height: Dp = Bauhaus.Rule) {
    Box(Modifier.fillMaxWidth().height(height).background(color))
}

@Composable
fun VRule(color: Color = Bauhaus.Ink, width: Dp = Bauhaus.Rule) {
    Box(Modifier.fillMaxHeight().width(width).background(color))
}

/** White panel, 2 dp black frame, optional primary field across the top above a black rule. */
@Composable
fun Panel(accent: Color? = null, modifier: Modifier = Modifier, padding: Dp = 16.dp, content: @Composable ColumnScope.() -> Unit) {
    Column(modifier.fillMaxWidth().background(Bauhaus.Ground).border(Bauhaus.Rule, Bauhaus.Ink, RectangleShape)) {
        if (accent != null) {
            Box(Modifier.fillMaxWidth().height(Bauhaus.Heavy).background(accent))
            HRule()
        }
        Column(Modifier.fillMaxWidth().padding(padding), verticalArrangement = Arrangement.spacedBy(12.dp), content = content)
    }
}

/** Index and tracked kicker, a big Jost display title, then a heavy black rule led by a primary block. */
@Composable
fun ScreenHeader(index: String, kicker: String, title: String, accent: Color, trailing: @Composable () -> Unit = {}) {
    Column(Modifier.fillMaxWidth().padding(top = 12.dp, bottom = 4.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Tracked("$index  |  $kicker", modifier = Modifier.weight(1f))
            trailing()
        }
        Text(title, style = jostStyle(48.sp, FontWeight.Bold), maxLines = 2, modifier = Modifier.semantics { heading() })
        Row(Modifier.fillMaxWidth().height(Bauhaus.Heavy)) {
            Box(Modifier.width(72.dp).fillMaxHeight().background(accent))
            Box(Modifier.weight(1f).fillMaxHeight().background(Bauhaus.Ink))
        }
    }
}

@Composable
fun SectionTitle(text: String, subtitle: String? = null) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(text, style = jostStyle(22.sp, FontWeight.Bold), modifier = Modifier.semantics { heading() })
        if (subtitle != null) Note(subtitle)
    }
}

/** Tracked label over a Jost number; `marker` puts a thick primary bar beside the value. */
@Composable
fun Readout(label: String, value: String, modifier: Modifier = Modifier, marker: Color? = null, size: TextUnit = 22.sp) {
    Column(modifier.semantics(mergeDescendants = true) {}, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Tracked(label, size = 11.sp)
        Row(Modifier.height(IntrinsicSize.Min), verticalAlignment = Alignment.CenterVertically) {
            if (marker != null) {
                Box(Modifier.width(Bauhaus.Heavy).fillMaxHeight().background(marker))
                Spacer(Modifier.width(8.dp))
            }
            Text(value, style = jostStyle(size, FontWeight.Medium), maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

/** A fader: 2 dp black track, a thick primary fill and a black vertical handle bar. */
@Composable
fun BauhausSlider(label: String, value: Double, range: ClosedFloatingPointRange<Double>, accent: Color = Bauhaus.Blue,
                  format: (Double) -> String, onChange: (Double) -> Unit) {
    val frac = ((value - range.start) / (range.endInclusive - range.start)).coerceIn(0.0, 1.0).toFloat()
    val step = (range.endInclusive - range.start) / 20
    Column(Modifier.fillMaxWidth().semantics(mergeDescendants = true) {
        contentDescription = label
        stateDescription = format(value)
        progressBarRangeInfo = ProgressBarRangeInfo(frac, 0f..1f)
        setProgress { f -> onChange(range.start + f.coerceIn(0f, 1f) * (range.endInclusive - range.start)); true }
        customActions = listOf(
            CustomAccessibilityAction("Increase") { onChange((value + step).coerceAtMost(range.endInclusive)); true },
            CustomAccessibilityAction("Decrease") { onChange((value - step).coerceAtLeast(range.start)); true },
        )
    }, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(verticalAlignment = Alignment.Bottom) {
            Tracked(label, modifier = Modifier.weight(1f))
            Spacer(Modifier.width(8.dp))
            Text(format(value), style = jostStyle(15.sp, FontWeight.Medium))
        }
        BoxWithConstraints(Modifier.fillMaxWidth().height(36.dp)) {
            val w = constraints.maxWidth.toFloat()
            val trackWidth = this.maxWidth
            fun set(x: Float) = onChange(range.start + (x / w).coerceIn(0f, 1f) * (range.endInclusive - range.start))
            Box(Modifier.fillMaxSize()
                .pointerInput(w) { detectTapGestures { set(it.x) } }
                .pointerInput(w) { detectDragGestures { change, _ -> set(change.position.x) } }) {
                Box(Modifier.fillMaxWidth().height(Bauhaus.Rule).align(Alignment.CenterStart).background(Bauhaus.Ink))
                Box(Modifier.fillMaxWidth(frac).height(Bauhaus.Heavy).align(Alignment.CenterStart).background(accent))
                Box(Modifier.align(Alignment.CenterStart).offset(x = (trackWidth - 8.dp) * frac).width(8.dp).height(30.dp).background(Bauhaus.Ink))
            }
        }
    }
}

/** Two adjoining OFF / ON segments in a 2 dp black frame; the active side is a flat field. */
@Composable
fun BauhausToggle(checked: Boolean, onChange: (Boolean) -> Unit, accent: Color = Bauhaus.Red, label: @Composable () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(role = Role.Switch) { onChange(!checked) }
        .semantics(mergeDescendants = true) { stateDescription = if (checked) "On" else "Off" },
        verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.weight(1f)) { label() }
        Spacer(Modifier.width(12.dp))
        Row(Modifier.height(IntrinsicSize.Min).border(Bauhaus.Rule, Bauhaus.Ink, RectangleShape)) {
            Segment("Off", !checked, Bauhaus.Ink)
            VRule()
            Segment("On", checked, accent)
        }
    }
}

@Composable
private fun Segment(t: String, active: Boolean, field: Color) {
    Box(Modifier.background(if (active) field else Bauhaus.Ground).heightIn(min = 44.dp).padding(horizontal = 14.dp),
        contentAlignment = Alignment.Center) {
        Tracked(t, color = if (active) Bauhaus.Ground else Bauhaus.Ink, size = 13.sp)
    }
}

/** Square button: a flat field, or white with a 2 dp black frame. The suffix is kept as written (units). */
@Composable
fun BauhausButton(text: String, icon: ImageVector? = null, fill: Color = Bauhaus.Ground, compact: Boolean = false,
                  modifier: Modifier = Modifier, suffix: String = "", onClick: () -> Unit) {
    val fg = Bauhaus.onField(fill)
    Row(modifier.heightIn(min = if (compact) 36.dp else Bauhaus.TapTarget).background(fill)
        .border(Bauhaus.Rule, Bauhaus.Ink, RectangleShape).clickable(role = Role.Button, onClick = onClick)
        .padding(horizontal = if (compact) 12.dp else 18.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        if (icon != null) Icon(icon, contentDescription = null, tint = fg, modifier = Modifier.size(if (compact) 16.dp else 18.dp))
        Text(Bauhaus.caps(text) + suffix, style = jostStyle(if (compact) 13.sp else 15.sp, FontWeight.SemiBold, fg, 1.2.sp), maxLines = 1)
    }
}

/** A flat field of colour holding one glyph, used as a key or row marker. */
@Composable
fun GlyphTile(icon: ImageVector, fill: Color, size: Dp = 24.dp) {
    Box(Modifier.size(size).background(fill).border(Bauhaus.Rule, Bauhaus.Ink, RectangleShape), contentAlignment = Alignment.Center) {
        Icon(icon, contentDescription = null, tint = Bauhaus.onField(fill), modifier = Modifier.size(size * 0.55f))
    }
}

@Composable
fun KeyRow(icon: ImageVector, color: Color, text: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        GlyphTile(icon, color)
        Tracked(text, color = Bauhaus.Ink, size = 11.sp)
    }
}

/** A row of readouts that becomes a single column at large font scales. */
@Composable
fun ReadoutRow(content: @Composable (Modifier) -> Unit) {
    val large = LocalConfiguration.current.fontScale >= 1.6f
    if (large) Column(verticalArrangement = Arrangement.spacedBy(12.dp)) { content(Modifier.fillMaxWidth()) }
    else Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) { content(Modifier.weight(1f)) }
}

/** Scrolling page: white ground edge to edge, content capped and centred on the grid. */
@Composable
fun Page(content: @Composable ColumnScope.() -> Unit) {
    Box(Modifier.fillMaxSize().background(Bauhaus.Ground).verticalScroll(androidx.compose.foundation.rememberScrollState()),
        contentAlignment = Alignment.TopCenter) {
        Column(Modifier.widthIn(max = Bauhaus.MaxContentWidth).fillMaxWidth().padding(start = 16.dp, end = 16.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp), content = content)
    }
}
