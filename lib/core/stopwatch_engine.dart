class StopwatchSave {
  final Duration duration;
  final String name;

  StopwatchSave({required this.duration, required this.name});

  Map<String, dynamic> toMap() => {
    'durationMs': duration.inMilliseconds,
    'name': name,
  };

  factory StopwatchSave.fromMap(Map<String, dynamic> map) => StopwatchSave(
    duration: Duration(milliseconds: map['durationMs']),
    name: map['name'],
  );
}

class StopwatchEngine {
  DateTime? _startUtc;
  Duration _accumulated = Duration.zero;
  bool _running = false;
  final List<StopwatchSave> _saves = <StopwatchSave>[];

  DateTime? get startUtc => _startUtc;
  Duration get accumulated => _accumulated;

  bool get isRunning => _running;
  List<StopwatchSave> get saves => List<StopwatchSave>.unmodifiable(_saves);

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

  void saveTime(DateTime nowUtc, String name) {
    final value = elapsed(nowUtc);
    _saves.add(StopwatchSave(duration: value, name: name));
  }

  void loadSaves(List<StopwatchSave> loadedSaves) {
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
