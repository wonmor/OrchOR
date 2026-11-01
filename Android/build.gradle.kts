// Plugin versions are pinned to artifacts already in the local Gradle cache.
plugins {
    id("com.android.application") version "8.13.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.2.20" apply false
    // Store screenshots are rendered on the JVM with layoutlib (see StoreScreenshots.kt).
    id("app.cash.paparazzi") version "2.0.0-alpha02" apply false
}
