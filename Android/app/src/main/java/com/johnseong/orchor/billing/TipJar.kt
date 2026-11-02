package com.johnseong.orchor.billing

import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.android.billingclient.api.Purchase.PurchaseState

/**
 * The tip jar: four consumable Play Billing products that unlock nothing. They are tips to the developer
 * (Orchestr Aerospace Inc. is not a charity), so the app never calls them donations.
 */
object TipJar {
    val productIds = listOf("orchor.tip.1", "orchor.tip.20", "orchor.tip.50", "orchor.tip.100")

    const val DISCLAIMER = "Tips are optional, unlock nothing, and are not tax-deductible. Everything in Orch-OR stays free."
    const val INTRO = "Orch-OR is free, with no ads and no tracking. If it has been useful, you can leave a tip to support its development."
    const val THANKS = "Thank you, truly. Your tip goes straight into keeping Orch-OR free, offline and honest about the science, and into the next things I build. It means a great deal."
    const val PENDING = "Your tip is pending, for example waiting on a cash payment or a family manager's approval. Nothing more to do here; if it goes through, thank you."
    const val UNAVAILABLE = "The tip jar can't reach Google Play right now. Check your connection and try again."

    val fallbackNames = mapOf(
        "orchor.tip.1" to "Small tip", "orchor.tip.20" to "Generous tip",
        "orchor.tip.50" to "Big tip", "orchor.tip.100" to "Huge tip",
    )

    fun failed(reason: String) = "The tip didn't go through ($reason). Nothing was charged."

    fun reason(code: Int): String = when (code) {
        BillingResponseCode.SERVICE_DISCONNECTED, BillingResponseCode.SERVICE_UNAVAILABLE,
        BillingResponseCode.NETWORK_ERROR -> "no connection to Google Play"
        BillingResponseCode.BILLING_UNAVAILABLE -> "Google Play billing isn't available on this device"
        BillingResponseCode.ITEM_UNAVAILABLE -> "this tip isn't available in your country"
        BillingResponseCode.ITEM_ALREADY_OWNED -> "a previous tip is still being completed; try again in a moment"
        else -> "Google Play returned an error"
    }

    /** Store order: by price, then by the fixed id order. */
    fun sorted(options: List<TipOption>) =
        options.sortedWith(compareBy<TipOption>({ it.priceMicros }, { productIds.indexOf(it.id) }))

    /** What the user sees after a purchase flow returns. */
    fun outcome(code: Int, purchaseStates: List<Int>): TipStatus = when (code) {
        BillingResponseCode.OK -> when {
            purchaseStates.any { it == PurchaseState.PURCHASED } -> TipStatus.Thanked
            purchaseStates.any { it == PurchaseState.PENDING } -> TipStatus.Pending
            else -> TipStatus.Idle
        }
        BillingResponseCode.USER_CANCELED -> TipStatus.Idle
        else -> TipStatus.Failed(failed(reason(code)))
    }
}

data class TipOption(val id: String, val name: String, val price: String, val priceMicros: Long)

sealed interface TipStatus {
    data object Idle : TipStatus
    data class Purchasing(val id: String) : TipStatus
    data object Pending : TipStatus
    data object Thanked : TipStatus
    data class Failed(val message: String) : TipStatus
}

enum class TipLoad { Loading, Ready, Unavailable }

/** Everything the tip jar UI draws; the billing client publishes it, screenshots stage it. */
data class TipJarUi(
    val load: TipLoad = TipLoad.Loading,
    val options: List<TipOption> = emptyList(),
    val status: TipStatus = TipStatus.Idle,
) {
    companion object {
        /** Staging for screenshots: the US prices set on Play Console. */
        fun preview(status: TipStatus = TipStatus.Idle) = TipJarUi(TipLoad.Ready,
            TipJar.productIds.zip(listOf(1L, 20L, 50L, 100L)).map { (id, d) ->
                TipOption(id, TipJar.fallbackNames.getValue(id), "$%d.00".format(d), d * 1_000_000)
            }, status)
    }
}
