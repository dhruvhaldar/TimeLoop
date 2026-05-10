import 'package:flutter/material.dart';
import 'stopwatch_view.dart';
import 'reminders_view.dart';
import 'checklist_view.dart';
import 'settings_view.dart';
import '../core/app_runtime.dart';
import '../core/reminder_schedule.dart';

class LayoutOrchestrator extends StatefulWidget {
  final AppRuntime runtime;
  const LayoutOrchestrator({super.key, required this.runtime});

  @override
  State<LayoutOrchestrator> createState() => _LayoutOrchestratorState();
}

class _LayoutOrchestratorState extends State<LayoutOrchestrator> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.runtime.addListener(_handleRuntimeChange);
  }

  @override
  void dispose() {
    widget.runtime.removeListener(_handleRuntimeChange);
    super.dispose();
  }

  void _handleRuntimeChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          labelType: NavigationRailLabelType.none,
          backgroundColor: Colors.black,
          unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.2), size: 24),
          selectedIconTheme: const IconThemeData(color: Colors.blueAccent, size: 28),
          useIndicator: true,
          indicatorColor: Colors.blueAccent.withOpacity(0.1),
          destinations: const [
            NavigationRailDestination(
              icon: Tooltip(message: "Stopwatch", child: Icon(Icons.timer_outlined)),
              selectedIcon: Icon(Icons.timer),
              label: Text('Stopwatch'),
            ),
            NavigationRailDestination(
              icon: Tooltip(message: "Reminders", child: Icon(Icons.notifications_none_rounded)),
              selectedIcon: Icon(Icons.notifications_rounded),
              label: Text('Reminders'),
            ),
            NavigationRailDestination(
              icon: Tooltip(message: "Checklist", child: Icon(Icons.checklist_rtl_rounded)),
              selectedIcon: Icon(Icons.checklist_rounded),
              label: Text('Checklist'),
            ),
            NavigationRailDestination(
              icon: Tooltip(message: "Settings", child: Icon(Icons.settings_outlined)),
              selectedIcon: Icon(Icons.settings),
              label: Text('Settings'),
            ),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
        Expanded(
          child: _getSelectedView(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Expanded(
          child: _getSelectedView(),
        ),
        BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.black,
          unselectedItemColor: Colors.white24,
          selectedItemColor: Colors.blueAccent,
          items: const [
            BottomNavigationBarItem(
              icon: Tooltip(message: "Stopwatch", child: Icon(Icons.timer_outlined)),
              activeIcon: Icon(Icons.timer),
              label: 'Stopwatch',
            ),
            BottomNavigationBarItem(
              icon: Tooltip(message: "Reminders", child: Icon(Icons.notifications_none_rounded)),
              activeIcon: Icon(Icons.notifications_rounded),
              label: 'Reminders',
            ),
            BottomNavigationBarItem(
              icon: Tooltip(message: "Checklist", child: Icon(Icons.checklist_rtl_rounded)),
              activeIcon: Icon(Icons.checklist_rounded),
              label: 'Checklist',
            ),
            BottomNavigationBarItem(
              icon: Tooltip(message: "Settings", child: Icon(Icons.settings_outlined)),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ],
    );
  }

  Widget _getSelectedView() {
    switch (_selectedIndex) {
      case 0:
        return StopwatchView(engine: widget.runtime.stopwatch);
      case 1:
        return RemindersView(
          reminders: widget.runtime.reminders,
          onToggle: (reminder) {
            widget.runtime.toggleReminder(reminder);
          },
          onDelete: (reminder) {
            widget.runtime.deleteReminder(reminder);
          },
          onAdd: (reminder) {
            widget.runtime.addReminder(reminder);
          },
        );
      case 2:
        return ChecklistView(
          items: widget.runtime.checklistItems,
          onToggle: (item) {
            setState(() {
              widget.runtime.toggleChecklistItem(item);
            });
          },
          onDelete: (id) {
            setState(() {
              widget.runtime.deleteChecklistItem(id);
            });
          },
          onAdd: (text) {
            setState(() {
              widget.runtime.addChecklistItem(text);
            });
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              widget.runtime.reorderChecklistItem(oldIndex, newIndex);
            });
          },
          onClearCompleted: () {
            setState(() {
              widget.runtime.clearCompletedChecklist();
            });
          },
        );
      case 3:
        return SettingsView(runtime: widget.runtime);
      default:
        return StopwatchView(engine: widget.runtime.stopwatch);
    }
  }
}
