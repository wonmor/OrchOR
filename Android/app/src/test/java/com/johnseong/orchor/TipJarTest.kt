package com.johnseong.orchor

import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.android.billingclient.api.Purchase.PurchaseState
import com.johnseong.orchor.billing.TipJar
import com.johnseong.orchor.billing.TipJarUi
import com.johnseong.orchor.billing.TipOption
import com.johnseong.orchor.billing.TipStatus
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TipJarTest {
    @Test fun outcomes() {
        assertEquals(TipStatus.Thanked, TipJar.outcome(BillingResponseCode.OK, listOf(PurchaseState.PURCHASED)))
        assertEquals(TipStatus.Pending, TipJar.outcome(BillingResponseCode.OK, listOf(PurchaseState.PENDING)))
        assertEquals(TipStatus.Idle, TipJar.outcome(BillingResponseCode.USER_CANCELED, emptyList()))
        val failed = TipJar.outcome(BillingResponseCode.NETWORK_ERROR, emptyList())
        assertTrue(failed is TipStatus.Failed && failed.message.contains("Nothing was charged"))
        assertTrue(TipJar.outcome(BillingResponseCode.ERROR, emptyList()) is TipStatus.Failed)
    }

    @Test fun sortedByPrice() {
        val o = { id: String, m: Long -> TipOption(id, id, "", m) }
        assertEquals(TipJar.productIds, TipJar.sorted(listOf(o("orchor.tip.100", 100_000_000), o("orchor.tip.1", 1_000_000),
            o("orchor.tip.50", 50_000_000), o("orchor.tip.20", 20_000_000))).map { it.id })
    }

    @Test fun copyNeverSaysDonationOrUsesDots() {
        val all = listOf(TipJar.DISCLAIMER, TipJar.INTRO, TipJar.THANKS, TipJar.PENDING, TipJar.UNAVAILABLE, TipJar.failed("x")) +
            TipJar.fallbackNames.values
        all.forEach { assertFalse(it, it.lowercase().contains("donat") || it.contains("·") || it.contains("•")) }
        assertEquals("Tips are optional, unlock nothing, and are not tax-deductible. Everything in Orch-OR stays free.", TipJar.DISCLAIMER)
        assertEquals(listOf("$1.00", "$20.00", "$50.00", "$100.00"), TipJarUi.preview().options.map { it.price })
    }
}
