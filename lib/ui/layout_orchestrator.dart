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
          labelType: NavigationRailLabelType.all,
          backgroundColor: Colors.black,
          unselectedIconTheme: const IconThemeData(color: Colors.white24),
          selectedIconTheme: const IconThemeData(color: Colors.blueAccent),
          unselectedLabelTextStyle: const TextStyle(color: Colors.white24),
          selectedLabelTextStyle: const TextStyle(color: Colors.blueAccent),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.timer),
              label: Text('Stopwatch'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.notifications),
              label: Text('Reminders'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.checklist),
              label: Text('Checklist'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings),
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
              icon: Icon(Icons.timer),
              label: 'Stopwatch',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Reminders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist),
              label: 'Checklist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
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
            setState(() {
              reminder.active = !reminder.active;
            });
          },
          onDelete: (reminder) {
            setState(() {
              widget.runtime.reminders.remove(reminder);
            });
          },
          onAdd: (reminder) {
            setState(() {
              widget.runtime.reminders.add(reminder);
            });
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
