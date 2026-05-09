import 'package:test/test.dart';
import 'package:timeloop/core/stopwatch_engine.dart';

void main() {
  test('stopwatch tracks elapsed time across pause/resume', () {
    final sw = StopwatchEngine();
    final t0 = DateTime.utc(2026, 1, 1, 0, 0, 0);

    sw.start(t0);
    expect(sw.elapsed(t0.add(const Duration(seconds: 10))), const Duration(seconds: 10));

    sw.pause(t0.add(const Duration(seconds: 12)));
    expect(sw.elapsed(t0.add(const Duration(seconds: 20))), const Duration(seconds: 12));

    sw.resume(t0.add(const Duration(seconds: 30)));
    expect(sw.elapsed(t0.add(const Duration(seconds: 35))), const Duration(seconds: 17));
  });

  test('recordLap stores running elapsed values', () {
    final sw = StopwatchEngine();
    final t0 = DateTime.utc(2026, 1, 1);

    sw.start(t0);
    final lap = sw.recordLap(t0.add(const Duration(milliseconds: 1500)));

    expect(lap, const Duration(milliseconds: 1500));
    expect(sw.laps.length, 1);
  });
}
