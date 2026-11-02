package com.johnseong.orchor.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.heading
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.johnseong.orchor.billing.*

/** Callbacks from the tip jar UI; the activity binds them to Play Billing. */
class TipJarActions(val onTip: (TipOption) -> Unit = {}, val onRetry: () -> Unit = {}, val onDismiss: () -> Unit = {})

/** The tip jar panel shown in About. Prices come from Google Play; nothing here unlocks anything. */
@Composable
fun TipJarPanel(ui: TipJarUi, actions: TipJarActions) {
    Panel(accent = Bauhaus.Blue) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            GlyphTile(Icons.Outlined.LocalCafe, Bauhaus.Yellow, 30.dp)
            Text("Tip Jar", style = jostStyle(22.sp, FontWeight.Bold), modifier = Modifier.semantics { heading() })
        }
        Text(TipJar.INTRO, style = jostStyle(16.sp).copy(lineHeight = 23.sp))
        if (ui.status == TipStatus.Thanked) Thanks(actions) else Choices(ui, actions)
        when (val s = ui.status) {
            TipStatus.Pending -> Message(TipJar.PENDING, Icons.Outlined.HourglassEmpty, Bauhaus.Yellow, actions)
            is TipStatus.Failed -> Message(s.message, Icons.Outlined.PriorityHigh, Bauhaus.Red, actions)
            else -> {}
        }
        Note(TipJar.DISCLAIMER)
    }
}

@Composable
private fun Choices(ui: TipJarUi, actions: TipJarActions) {
    when (ui.load) {
        TipLoad.Loading -> Row(Modifier.heightIn(min = Bauhaus.TapTarget), verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            CircularProgressIndicator(Modifier.size(20.dp), color = Bauhaus.Ink, strokeWidth = 2.dp)
            Tracked("Loading prices", size = 11.sp)
        }
        TipLoad.Unavailable -> Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Note(TipJar.UNAVAILABLE)
            BauhausButton("Try again", Icons.Outlined.Refresh, compact = true, onClick = actions.onRetry)
        }
        TipLoad.Ready -> {
            val busy = ui.status is TipStatus.Purchasing
            val rows = if (isWide()) ui.options.chunked(2) else ui.options.map { listOf(it) }
            rows.forEach { row ->
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    row.forEach { o -> TipButton(o, ui.status == TipStatus.Purchasing(o.id), busy, actions, Modifier.weight(1f)) }
                    if (row.size == 1 && isWide()) Spacer(Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun TipButton(o: TipOption, active: Boolean, anyBusy: Boolean, actions: TipJarActions, modifier: Modifier) {
    val fill = if (active) Bauhaus.Blue else Bauhaus.Ground
    val fg = Bauhaus.onField(fill)
    Row(modifier.heightIn(min = Bauhaus.TapTarget).background(fill).border(Bauhaus.Rule, Bauhaus.Ink, RectangleShape)
        .clickable(enabled = !anyBusy, role = Role.Button) { actions.onTip(o) }
        .semantics(mergeDescendants = true) { contentDescription = "${o.name}, ${o.price}. Leaves a tip; unlocks nothing." }
        .padding(horizontal = 18.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(Bauhaus.caps(o.name), style = jostStyle(15.sp, FontWeight.SemiBold, fg, 1.2.sp), modifier = Modifier.weight(1f), maxLines = 1)
        if (active) CircularProgressIndicator(Modifier.size(18.dp), color = fg, strokeWidth = 2.dp)
        else Text(o.price, style = jostStyle(15.sp, FontWeight.SemiBold, fg, 1.2.sp), maxLines = 1)
    }
}

@Composable
private fun Thanks(actions: TipJarActions) {
    Column(Modifier.fillMaxWidth().background(Bauhaus.Soft).border(Bauhaus.Rule, Bauhaus.Ink, RectangleShape).padding(14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            GlyphTile(Icons.Filled.Favorite, Bauhaus.Red, 44.dp)
            Text("Thank you", style = jostStyle(34.sp, FontWeight.Bold), modifier = Modifier.semantics { heading() })
        }
        Text(TipJar.THANKS, style = jostStyle(16.sp).copy(lineHeight = 23.sp))
        BauhausButton("Done", Icons.Outlined.Check, compact = true, onClick = actions.onDismiss)
    }
}

@Composable
private fun Message(text: String, icon: androidx.compose.ui.graphics.vector.ImageVector, fill: Color, actions: TipJarActions) {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.Top) {
        GlyphTile(icon, fill, 26.dp)
        Text(text, style = jostStyle(14.sp, color = Bauhaus.Ink), modifier = Modifier.weight(1f))
        Box(Modifier.size(Bauhaus.TapTarget).clickable(role = Role.Button, onClick = actions.onDismiss)
            .semantics { contentDescription = "Dismiss" }, contentAlignment = Alignment.Center) {
            Icon(Icons.Outlined.Close, contentDescription = null, tint = Bauhaus.Ink)
        }
    }
}

/** The tip jar on its own, opened from the small link at the foot of the Learn tab. */
@Composable
fun TipJarScreen(ui: TipJarUi, actions: TipJarActions, onClose: () -> Unit) {
    Page {
        ScreenHeader("00", "Support Orch-OR", "tip jar", Bauhaus.Blue) {
            BauhausButton("Close", Icons.Outlined.Close, compact = true, onClick = onClose)
        }
        TipJarPanel(ui, actions)
    }
}

/** A small, quiet text link. No banner, no badge, no prompt. */
@Composable
fun SupportLink(onClick: () -> Unit) {
    Row(Modifier.heightIn(min = Bauhaus.TapTarget).clickable(role = Role.Button, onClick = onClick),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Icon(Icons.Outlined.LocalCafe, contentDescription = null, tint = Bauhaus.InkSecondary, modifier = Modifier.size(16.dp))
        Text("Support Orch-OR", style = jostStyle(14.sp, color = Bauhaus.InkSecondary).copy(textDecoration = TextDecoration.Underline))
    }
}
