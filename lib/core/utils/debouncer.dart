import 'dart:async';

/// A utility class to debounce function calls
/// Prevents rapid successive calls by delaying execution until
/// a specified duration has passed since the last call
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Call the function, canceling any pending calls
  void call(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  /// Cancel any pending calls
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose of the debouncer
  void dispose() {
    cancel();
  }
}
