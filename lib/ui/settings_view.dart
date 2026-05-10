import 'package:flutter/material.dart';
import 'dart:io';
import '../core/app_runtime.dart';
import '../core/platform_service.dart';
import '../core/persistence_service.dart';

class SettingsView extends StatefulWidget {
  final AppRuntime runtime;
  const SettingsView({super.key, required this.runtime});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _alwaysOnTop = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            "SETTINGS",
            style: TextStyle(
              color: Colors.grey.shade400,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          _buildSettingCard(
            title: "Debug Logging",
            subtitle: "Enable logging to timeloop_debug.log for troubleshooting.",
            trailing: Switch(
              value: widget.runtime.debugEnabled,
              onChanged: (value) {
                setState(() {
                  widget.runtime.debugEnabled = value;
                  PlatformService.instance.debugEnabled = value;
                });
              },
              activeColor: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: "Reminder Alert Mode",
            subtitle: "Choose between just hearing a beep or beep + popup alert.",
            trailing: DropdownButton<ReminderMode>(
              value: widget.runtime.reminderMode,
              dropdownColor: Colors.grey.shade900,
              underline: Container(),
              items: const [
                DropdownMenuItem(
                  value: ReminderMode.beepOnly,
                  child: Text("Beep Only", style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: ReminderMode.beepAndPopup,
                  child: Text("Beep + Popup", style: TextStyle(color: Colors.white)),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  setState(() {
                    widget.runtime.reminderMode = mode;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: "Always on Top",
            subtitle: "Keep the TimeLoop window above all other applications.",
            trailing: Switch(
              value: _alwaysOnTop,
              onChanged: (value) async {
                setState(() {
                  _alwaysOnTop = value;
                });
                await PlatformService.instance.setAlwaysOnTop(value);
              },
              activeColor: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "DATA MANAGEMENT",
            style: TextStyle(
              color: Colors.grey.shade400,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: "Backup Data",
            subtitle: "Export all data to 'timeloop_backup.json' in the app folder.",
            trailing: IconButton(
              onPressed: () async {
                try {
                  final path = await PersistenceService.instance.exportBackup();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Backup saved to: $path"),
                      backgroundColor: Colors.blueAccent,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Backup failed: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              },
              icon: const Icon(Icons.backup, color: Colors.blueAccent),
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            title: "Restore Data",
            subtitle: "Import data from 'timeloop_backup.json' (Destructive).",
            trailing: IconButton(
              onPressed: () => _confirmRestore(context),
              icon: const Icon(Icons.restore, color: Colors.orangeAccent),
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              "TimeLoop v1.0.0",
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("Restore Data?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "This will overwrite all current reminders, checklist items, and history. Are you sure?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final file = File('timeloop_backup.json');
              if (await file.exists()) {
                try {
                  final jsonString = await file.readAsString();
                  await PersistenceService.instance.importBackup(jsonString);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Data restored. Please restart the app."),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Restore failed: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Backup file 'timeloop_backup.json' not found."),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text("RESTORE", style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }
}
