class StopwatchEngine {
  DateTime? _startUtc;
  Duration _accumulated = Duration.zero;
  bool _running = false;
  final List<Duration> _laps = <Duration>[];

  bool get isRunning => _running;
  List<Duration> get laps => List<Duration>.unmodifiable(_laps);

  void start(DateTime nowUtc) {
    if (_running) return;
    _running = true;
    _startUtc = nowUtc.toUtc();
  }

  void pause(DateTime nowUtc) {
    if (!_running || _startUtc == null) return;
    _accumulated += nowUtc.toUtc().difference(_startUtc!);
    _startUtc = null;
    _running = false;
  }

  void resume(DateTime nowUtc) => start(nowUtc);

  void reset() {
    _running = false;
    _startUtc = null;
    _accumulated = Duration.zero;
    _laps.clear();
  }

  Duration elapsed(DateTime nowUtc) {
    if (!_running || _startUtc == null) {
      return _accumulated;
    }
    return _accumulated + nowUtc.toUtc().difference(_startUtc!);
  }

  Duration recordLap(DateTime nowUtc) {
    final value = elapsed(nowUtc);
    _laps.add(value);
    return value;
  }

  Duration reconcileAfterWake(DateTime wakeUtc) {
    return elapsed(wakeUtc);
  }
}
