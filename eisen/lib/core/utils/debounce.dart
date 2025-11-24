import 'dart:async';

/// Simple debounce helper to coalesce rapid UI events.
///
/// Call [run] with a callback; if another call happens within [delay],
/// the previous callback is cancelled. Useful for filter/range changes
/// to avoid unnecessary recomputation/redraws.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 250)});

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
