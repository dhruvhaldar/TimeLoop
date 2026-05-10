class StopwatchEngine {
  DateTime? _startUtc;
  Duration _accumulated = Duration.zero;
  bool _running = false;
  final List<Duration> _saves = <Duration>[];

  DateTime? get startUtc => _startUtc;
  Duration get accumulated => _accumulated;

  bool get isRunning => _running;
  List<Duration> get saves => List<Duration>.unmodifiable(_saves);

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
  }

  void clearSaves() {
    _saves.clear();
  }

  void deleteSaveAt(int index) {
    if (index >= 0 && index < _saves.length) {
      _saves.removeAt(index);
    }
  }

  Duration elapsed(DateTime nowUtc) {
    if (!_running || _startUtc == null) {
      return _accumulated;
    }
    return _accumulated + nowUtc.toUtc().difference(_startUtc!);
  }

  Duration saveTime(DateTime nowUtc) {
    final value = elapsed(nowUtc);
    _saves.add(value);
    return value;
  }

  void loadSaves(List<Duration> loadedSaves) {
    _saves.clear();
    _saves.addAll(loadedSaves);
  }

  void restoreState({
    required bool isRunning,
    DateTime? startUtc,
    required Duration accumulated,
  }) {
    _running = isRunning;
    _startUtc = startUtc;
    _accumulated = accumulated;
  }

  Duration reconcileAfterWake(DateTime wakeUtc) {
    return elapsed(wakeUtc);
  }
}
