import 'dart:async';
import 'package:flutter/material.dart';
import '../core/stopwatch_engine.dart';
import '../core/persistence_service.dart';

class StopwatchView extends StatefulWidget {
  final StopwatchEngine engine;
  const StopwatchView({super.key, required this.engine});

  @override
  State<StopwatchView> createState() => _StopwatchViewState();
}

class _StopwatchViewState extends State<StopwatchView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (widget.engine.isRunning) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    String ms = threeDigits(d.inMilliseconds.remainder(1000));
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
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                _formatDuration(elapsed),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                  fontFamily: 'Courier', // Using a monospace font for stability
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
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
                icon: widget.engine.isRunning ? Icons.pause : Icons.play_arrow,
                label: widget.engine.isRunning ? "PAUSE" : "START",
                color: widget.engine.isRunning ? Colors.orange : Colors.greenAccent,
              ),
              const SizedBox(width: 20),
              _buildActionButton(
                onPressed: () async {
                  setState(() {
                    widget.engine.saveTime(DateTime.now());
                  });
                  await PersistenceService.instance.saveSaves(widget.engine.saves);
                },
                icon: Icons.save,
                label: "SAVE",
                color: Colors.blueAccent,
                enabled: widget.engine.isRunning,
              ),
              const SizedBox(width: 20),
              _buildActionButton(
                onPressed: () async {
                  setState(() {
                    widget.engine.reset();
                  });
                },
                icon: Icons.refresh,
                label: "RESET",
                color: Colors.redAccent,
              ),
            ],
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
    required Color color,
    bool enabled = true,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.2),
            foregroundColor: color,
            padding: const EdgeInsets.all(20),
            shape: const CircleBorder(),
            side: BorderSide(color: color.withOpacity(0.5)),
          ),
          child: Icon(icon, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
        ),
      ],
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
          final saveTime = saves[saves.length - 1 - index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "SAVE $saveIndex",
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
                Text(
                  _formatDuration(saveTime),
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
          );
        },
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
