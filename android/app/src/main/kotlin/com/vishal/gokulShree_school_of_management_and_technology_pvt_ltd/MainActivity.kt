package com.vishal.gokulShree_school_of_management_and_technology_pvt_ltd

import android.os.Build
import android.window.OnBackInvokedDispatcher
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // On Android 13+ (API 33+), the Activity base class registers its own
        // OnBackInvokedCallback that calls finish() — overriding Flutter's callback.
        // We register our own callback at PRIORITY_OVERLAY (higher priority) that
        // delegates to FlutterActivity's onBackPressed(), giving Flutter (and our
        // PopScope / GoRouter) full control over back navigation.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_OVERLAY
            ) {
                // Delegate to Flutter's back handling — this will trigger PopScope
                @Suppress("DEPRECATION")
                onBackPressed()
            }
        }
    }
}
