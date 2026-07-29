package com.beshariq.driver_app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

/**
 * Yangi buyurtma to'liq ekran (full screen intent) signali bosilganda yoki
 * tizim tomonidan ochilganda — ekran yonsin va lock ekran ustidan ko'rinsin.
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }
}
