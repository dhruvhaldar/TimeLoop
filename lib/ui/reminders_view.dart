import 'package:flutter/material.dart';
import '../core/reminder_schedule.dart';

class RemindersView extends StatefulWidget {
  final List<ReminderSchedule> reminders;
  final Function(ReminderSchedule) onToggle;
  final Function(ReminderSchedule) onDelete;
  final Function(ReminderSchedule) onAdd;

  const RemindersView({
    super.key,
    required this.reminders,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  State<RemindersView> createState() => _RemindersViewState();
}

class _RemindersViewState extends State<RemindersView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "REMINDERS",
                style: TextStyle(
                  color: Colors.blueAccent.shade100,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Tooltip(
                message: "Add new reminder",
                child: IconButton(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.blueAccent, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: widget.reminders.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: widget.reminders.length,
                    itemBuilder: (context, index) {
                      return _buildReminderCard(widget.reminders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "No reminders scheduled",
            style: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(ReminderSchedule reminder) {
    return Semantics(
      label: "Reminder: ${reminder.message}, every ${reminder.interval.inMinutes} minutes",
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.015),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: reminder.active
                ? Colors.blueAccent.withOpacity(0.15)
                : Colors.white.withOpacity(0.03),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    reminder.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Every ${reminder.interval.inMinutes} min",
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Next: ${reminder.nextTriggerUtc.toLocal().toString().split(' ')[1].substring(0, 5)}",
                    style: TextStyle(color: Colors.blueAccent.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 32,
                  child: Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: reminder.active,
                      onChanged: (_) => widget.onToggle(reminder),
                      activeColor: Colors.blueAccent,
                    ),
                  ),
                ),
                Tooltip(
                  message: "Delete reminder",
                  child: IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.3), size: 18),
                    onPressed: () => widget.onDelete(reminder),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final messageController = TextEditingController();
    final intervalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text("New Reminder", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: "Message",
                labelStyle: TextStyle(color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            TextField(
              controller: intervalController,
              decoration: const InputDecoration(
                labelText: "Interval (minutes)",
                labelStyle: TextStyle(color: Colors.white54),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              final interval = int.tryParse(intervalController.text) ?? 20;
              final reminder = ReminderSchedule(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                message: messageController.text.isEmpty ? "Reminder" : messageController.text,
                interval: Duration(minutes: interval),
                nextTriggerUtc: DateTime.now().toUtc().add(Duration(minutes: interval)),
              );
              widget.onAdd(reminder);
              Navigator.pop(context);
            },
            child: const Text("ADD"),
          ),
        ],
      ),
    );
  }
}
