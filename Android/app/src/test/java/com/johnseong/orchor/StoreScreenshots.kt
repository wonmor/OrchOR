package com.johnseong.orchor

import app.cash.paparazzi.DeviceConfig
import app.cash.paparazzi.Paparazzi
import com.android.resources.Density
import com.android.resources.ScreenOrientation
import com.johnseong.orchor.model.OrchORSimulation
import com.johnseong.orchor.billing.TipJarUi
import com.johnseong.orchor.billing.TipStatus
import com.johnseong.orchor.ui.SimState
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * Play Store screenshots, rendered with layoutlib from the real composables and a seeded, staged model
 * (the same staging the debug build accepts via intent extras). Run:
 *   ./gradlew :app:recordPaparazziDebug --tests '*StoreScreenshots*'
 * Output: app/src/test/snapshots/images/.
 */
@RunWith(Parameterized::class)
class StoreScreenshots(private val device: String) {
    companion object {
        @JvmStatic @Parameterized.Parameters(name = "{0}")
        fun devices() = listOf("phone", "tablet7", "tablet10")

        private fun config(name: String) = when (name) {
            // 1080 × 2160 keeps within Play's 2:1 limit.
            "phone" -> DeviceConfig.PIXEL_5.copy(screenHeight = 2160, screenWidth = 1080, xdpi = 440, ydpi = 440, density = Density.create(440))
            "tablet7" -> DeviceConfig.NEXUS_7.copy(screenWidth = 1920, screenHeight = 1200, xdpi = 320, ydpi = 320, density = Density.XHIGH,
                orientation = ScreenOrientation.LANDSCAPE)
            else -> DeviceConfig.NEXUS_10.copy(screenWidth = 2560, screenHeight = 1600, xdpi = 300, ydpi = 300, density = Density.XHIGH,
                orientation = ScreenOrientation.LANDSCAPE)
        }
    }

    @get:Rule val paparazzi = Paparazzi(deviceConfig = config(device), maxPercentDifference = 1.0, useDeviceResolution = true)

    private fun staged(stage: String) = SimState(OrchORSimulation(seed = 2026uL)).apply { update { stage(stage) } }

    @Test fun s1_microtubule() = paparazzi.snapshot("1-microtubule") { App(staged("hero"), 0, false) }
    @Test fun s2_timeline() = paparazzi.snapshot("2-timeline") { App(staged("timeline"), 1, false) }
    @Test fun s3_calculator() = paparazzi.snapshot("3-calculator") { App(staged("timeline"), 2, false) }
    @Test fun s4_learn() = paparazzi.snapshot("4-learn") { App(staged("timeline"), 3, false) }
    @Test fun s5_about() = paparazzi.snapshot("5-about") { App(staged("timeline"), 0, true) }
    // Tip jar (not a store screenshot; kept for review and docs).
    @Test fun t1_tipjar() = paparazzi.snapshot("tipjar") { App(staged("timeline"), 3, false, TipJarUi.preview(), startTipJar = true) }
    @Test fun t2_tipjar_thanks() = paparazzi.snapshot("tipjar-thanks") { App(staged("timeline"), 3, false, TipJarUi.preview(TipStatus.Thanked), startTipJar = true) }
}
