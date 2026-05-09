import 'package:flutter/material.dart';
import '../core/app_runtime.dart';
import '../core/platform_service.dart';

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
}
