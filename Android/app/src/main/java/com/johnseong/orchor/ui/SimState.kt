package com.johnseong.orchor.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.setValue
import com.johnseong.orchor.model.OrchORSimulation

/** Wraps the plain-Kotlin model for Compose: `frame` bumps after every change so readers recompose. */
class SimState(val sim: OrchORSimulation = OrchORSimulation()) {
    var frame by mutableLongStateOf(0L)
        private set

    fun tick(realDt: Double) { sim.tick(realDt); frame++ }
    fun update(block: OrchORSimulation.() -> Unit) { sim.block(); frame++ }
}
