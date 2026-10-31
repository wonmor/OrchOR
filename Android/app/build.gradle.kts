import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

// Release signing: local.properties (never committed) names a keystore.properties file with
// storeFile / storePassword / keyAlias / keyPassword. A relative storeFile resolves against that
// file's folder (or its app/ module). Without it, release builds fall back to the debug key so they still assemble.
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}
val signingFile = localProps.getProperty("signing.properties")?.let { File(it) }?.takeIf { it.exists() }
val signingProps = Properties().apply { signingFile?.let { f -> FileInputStream(f).use { load(it) } } }

android {
    namespace = "com.johnseong.orchor"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.johnseong.orchor"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.1"
    }

    signingConfigs {
        if (signingFile != null) {
            create("release") {
                val store = signingProps.getProperty("storeFile")
                // A relative path is tried against the properties file's folder, then its app/ module
                // (ClassFinder's file is written relative to its app module).
                storeFile = File(store).takeIf { it.isAbsolute }
                    ?: listOf(File(signingFile.parentFile, store), File(signingFile.parentFile, "app/$store"))
                        .map { it.canonicalFile }.firstOrNull { it.exists() }
                    ?: File(signingFile.parentFile, store)
                storePassword = signingProps.getProperty("storePassword")
                keyAlias = signingProps.getProperty("keyAlias")
                keyPassword = signingProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = if (signingFile != null) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildFeatures { compose = true }
    testOptions { unitTests.isReturnDefaultValues = true }
}

kotlin {
    compilerOptions { jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17) }
}

dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.activity:activity-compose:1.9.3")

    val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    debugImplementation("androidx.compose.ui:ui-tooling")
    implementation("androidx.compose.ui:ui-tooling-preview")

    testImplementation("junit:junit:4.13.2")
}
