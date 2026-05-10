import 'dart:async';
import 'package:flutter/material.dart';
import '../core/stopwatch_engine.dart';
import '../core/persistence_service.dart';
import '../core/app_runtime.dart';
import 'digit_flipper.dart';

class StopwatchView extends StatefulWidget {
  final StopwatchEngine engine;
  final TimerFormat timerFormat;
  const StopwatchView({super.key, required this.engine, required this.timerFormat});

  @override
  State<StopwatchView> createState() => _StopwatchViewState();
}

class _StopwatchViewState extends State<StopwatchView> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.6,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (widget.engine.isRunning) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (widget.timerFormat == TimerFormat.minutesOnly) {
      return "${d.inMinutes}";
    }
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    String ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, "0");
    return "$hours:$minutes:$seconds.$ms";
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = widget.engine.elapsed(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            "STOPWATCH",
            style: TextStyle(
              color: Colors.deepPurple.shade200,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final glowOpacity = widget.engine.isRunning ? _pulseController.value : 0.0;
                  final timeStr = _formatDuration(elapsed);
                  final isRunning = widget.engine.isRunning;
                  final activeColor = isRunning ? Colors.cyanAccent : Colors.white.withOpacity(0.3);
                  final shadowColor = isRunning ? Colors.cyanAccent : Colors.transparent;
                  
                  if (widget.timerFormat == TimerFormat.minutesOnly) {
                    final chars = timeStr.split('');
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: chars.map((c) => DigitFlipper(
                          char: c,
                          style: TextStyle(
                            fontSize: 120,
                            fontWeight: FontWeight.w900,
                            color: activeColor,
                            fontFamily: 'Lucida Console',
                            shadows: [
                              Shadow(
                                color: shadowColor.withOpacity(glowOpacity * 0.5),
                                blurRadius: 20 * glowOpacity,
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    );
                  }

                  final parts = timeStr.split('.');
                  final mainChars = parts[0].split('');
                  final msChars = parts[1].split('');
                  
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        ...mainChars.map((c) => DigitFlipper(
                          char: c,
                          style: TextStyle(
                            fontSize: 84,
                            fontWeight: FontWeight.w900,
                            color: activeColor,
                            letterSpacing: 2,
                            fontFamily: 'Lucida Console',
                            fontFeatures: const [FontFeature.tabularFigures()],
                            shadows: [
                              Shadow(
                                color: shadowColor.withOpacity(glowOpacity * 0.5),
                                blurRadius: 20 * glowOpacity,
                              ),
                            ],
                          ),
                        )),
                        Text(
                          ".",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: activeColor.withOpacity(isRunning ? 0.3 : 0.1),
                            fontFamily: 'Lucida Console',
                          ),
                        ),
                        ...msChars.map((c) => DigitFlipper(
                          char: c,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: activeColor.withOpacity(isRunning ? 0.3 : 0.1),
                            fontFamily: 'Lucida Console',
                          ),
                        )),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 40),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  onPressed: () {
                    setState(() {
                      if (widget.engine.isRunning) {
                        widget.engine.pause(DateTime.now());
                      } else {
                        widget.engine.start(DateTime.now());
                      }
                    });
                  },
                  icon: widget.engine.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  label: widget.engine.isRunning ? "PAUSE" : "START",
                  tooltip: widget.engine.isRunning ? "Pause timer" : "Start timer",
                  color: widget.engine.isRunning ? Colors.orangeAccent : Colors.greenAccent,
                ),
                const SizedBox(width: 32),
                _buildActionButton(
                  onPressed: () => _showSaveDialog(context),
                  icon: Icons.save_outlined,
                  label: "SAVE",
                  tooltip: "Save timestamp with a name",
                  color: Colors.blueAccent,
                  enabled: widget.engine.isRunning,
                ),
                const SizedBox(width: 32),
                _buildActionButton(
                  onPressed: () async {
                    setState(() {
                      widget.engine.reset();
                    });
                  },
                  icon: Icons.restart_alt_rounded,
                  label: "RESET",
                  tooltip: "Reset the timer",
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: _buildSaveList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required String tooltip,
    required Color color,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: tooltip,
        child: Column(
          children: [
            ElevatedButton(
              onPressed: enabled ? onPressed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.1),
                foregroundColor: color,
                elevation: 0,
                padding: const EdgeInsets.all(16),
                shape: const CircleBorder(),
                side: BorderSide(color: color.withOpacity(0.2)),
              ),
              child: Icon(icon, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveList() {
    final saves = widget.engine.saves;
    if (saves.isEmpty) {
      return Center(
        child: Text(
          "No saved times yet",
          style: TextStyle(color: Colors.white.withOpacity(0.3)),
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        itemCount: saves.length,
        itemBuilder: (context, index) {
          final saveIndex = saves.length - index;
          final save = saves[saves.length - 1 - index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      save.name.isEmpty ? "SAVE $saveIndex" : save.name,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatDuration(save.duration),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _confirmDeleteSave(context, saves.length - 1 - index),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Save Timestamp", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter a name (e.g. Lap 1, Split, etc.)",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              Navigator.pop(context);
              setState(() {
                widget.engine.saveTime(DateTime.now(), name);
              });
              await PersistenceService.instance.saveSaves(widget.engine.saves);
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSave(BuildContext context, int engineIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Delete Save?", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete this recorded time?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                widget.engine.deleteSaveAt(engineIndex);
              });
              await PersistenceService.instance.saveSaves(widget.engine.saves);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
