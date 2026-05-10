import 'package:flutter/material.dart';
import '../core/checklist_item.dart';

class ChecklistView extends StatefulWidget {
  final List<ChecklistItem> items;
  final Function(ChecklistItem) onToggle;
  final Function(String) onDelete;
  final Function(String) onAdd;
  final VoidCallback onClearCompleted;

  const ChecklistView({
    super.key,
    required this.items,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
    required this.onClearCompleted,
  });

  @override
  State<ChecklistView> createState() => _ChecklistViewState();
}

class _ChecklistViewState extends State<ChecklistView> {
  final _textController = TextEditingController();

  void _submit() {
    if (_textController.text.isNotEmpty) {
      widget.onAdd(_textController.text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
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
                "CHECKLIST",
                style: TextStyle(
                  color: Colors.blueAccent.shade100,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.items.any((item) => item.isCompleted))
                TextButton.icon(
                  onPressed: widget.onClearCompleted,
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                  label: const Text("Clear Done", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Add a new task...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: Colors.blueAccent),
                  onPressed: _submit,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: widget.items.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return _buildChecklistItem(item);
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
          Icon(Icons.checklist, size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "Nothing to do yet",
            style: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isCompleted 
              ? Colors.blueAccent.withOpacity(0.1) 
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (_) => widget.onToggle(item),
          activeColor: Colors.blueAccent,
          checkColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          item.text,
          style: TextStyle(
            color: item.isCompleted ? Colors.white.withOpacity(0.4) : Colors.white,
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close, color: Colors.white.withOpacity(0.2), size: 18),
          onPressed: () => widget.onDelete(item.id),
        ),
      ),
    );
  }
}
