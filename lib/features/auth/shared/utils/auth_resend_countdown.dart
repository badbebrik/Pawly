import 'dart:async';

class AuthResendCountdown {
  Timer? _timer;

  void start(
    int seconds, {
    required void Function(int seconds) onChanged,
  }) {
    _timer?.cancel();

    var remaining = seconds > 0 ? seconds : 0;
    onChanged(remaining);

    if (remaining == 0) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining -= 1;
      if (remaining <= 0) {
        timer.cancel();
        onChanged(0);
        return;
      }

      onChanged(remaining);
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
