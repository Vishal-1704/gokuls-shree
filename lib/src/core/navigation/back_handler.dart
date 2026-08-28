import 'package:flutter/widgets.dart';

/// Global singleton WidgetsBindingObserver for Android back button.
///
/// WHY SINGLETON: _RoleShellState gets created/disposed during GoRouter
/// rebuilds, so observers registered in initState() can vanish before back
/// is pressed. This singleton is registered ONCE at app startup and never
/// removed, ensuring didPopRoute() is always available.
///
/// WHY DEDUPLICATION: Samsung Galaxy (and possibly other OEMs) fires BOTH
/// the legacy onBackPressed() AND the OnBackInvokedDispatcher callback for
/// each single physical back press. Our PRIORITY_OVERLAY callback calls
/// onBackPressed() again, producing 2–3 popRoute() signals per gesture.
/// Without deduplication, the "double-back to exit" logic sees the second
/// duplicate as the "second back" and exits immediately on the FIRST press.
class BackHandler with WidgetsBindingObserver {
  BackHandler._();
  static final BackHandler instance = BackHandler._();

  /// The current active handler set by whatever screen is on top.
  Future<bool> Function()? handler;

  /// Deduplication: timestamp of the last time we actually processed a back.
  DateTime? _lastProcessed;

  /// Fallback double-back timer when no handler is registered.
  DateTime? _lastFallbackBack;

  static const _dedupWindow = Duration(milliseconds: 300);

  @override
  Future<bool> didPopRoute() async {
    final now = DateTime.now();

    // ── Deduplication ──────────────────────────────────────────────────────
    // Samsung fires legacy onBackPressed() AND our PRIORITY_OVERLAY callback
    // for a single physical gesture, producing 2–3 popRoute() calls within
    // milliseconds. Only the FIRST one should be processed.
    if (_lastProcessed != null &&
        now.difference(_lastProcessed!) < _dedupWindow) {
      debugPrint('⏭️  BackHandler: duplicate popRoute ignored (${now.difference(_lastProcessed!).inMilliseconds}ms gap)');
      return true; // consume silently — already handled
    }
    _lastProcessed = now;

    debugPrint('🌐 BackHandler.didPopRoute — handler=${handler != null ? "set" : "null"}');

    if (handler != null) {
      return handler!();
    }

    // ── Fallback: no screen registered a handler ───────────────────────────
    debugPrint('⚠️  BackHandler: no handler — fallback double-back');
    if (_lastFallbackBack == null ||
        now.difference(_lastFallbackBack!) > const Duration(seconds: 2)) {
      _lastFallbackBack = now;
      return true; // swallow first press
    }
    return false; // second press within 2s → let system exit
  }
}
