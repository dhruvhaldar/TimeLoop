import 'package:flutter/material.dart';
import '../core/checklist_item.dart';

class ChecklistView extends StatefulWidget {
  final List<ChecklistItem> items;
  final Function(ChecklistItem) onToggle;
  final Function(String) onDelete;
  final Function(String) onAdd;
  final Function(int, int) onReorder;
  final VoidCallback onClearCompleted;

  const ChecklistView({
    super.key,
    required this.items,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
    required this.onReorder,
    required this.onClearCompleted,
  });

  @override
  State<ChecklistView> createState() => _ChecklistViewState();
}

class _ChecklistViewState extends State<ChecklistView> {
  final _textController = TextEditingController();
  bool _isAutoSort = true;

  List<ChecklistItem> get _displayedItems {
    if (_isAutoSort) {
      final list = List<ChecklistItem>.from(widget.items);
      list.sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return a.id.compareTo(b.id);
        }
        return a.isCompleted ? 1 : -1;
      });
      return list;
    }
    return widget.items;
  }

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isAutoSort = !_isAutoSort;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isAutoSort ? Icons.auto_awesome : Icons.sort,
                      color: _isAutoSort ? Colors.blueAccent : Colors.white24,
                      size: 20,
                    ),
                    tooltip: _isAutoSort ? "Auto-sort active" : "Manual sorting active",
                  ),
                  if (widget.items.any((item) => item.isCompleted)) ...[
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: widget.onClearCompleted,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                      label: const Text("Clear Done", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "What needs to be done?",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
                border: InputBorder.none,
                suffixIcon: Tooltip(
                  message: "Add task",
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.blueAccent, size: 22),
                    onPressed: _submit,
                  ),
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: widget.items.isEmpty
                ? _buildEmptyState()
                : Scrollbar(
                    thumbVisibility: true,
                    child: ReorderableListView.builder(
                      itemCount: _displayedItems.length,
                      onReorder: (oldIndex, newIndex) {
                        if (_isAutoSort) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Disable Auto-Sort to use custom sorting"),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          return;
                        }
                        widget.onReorder(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final item = _displayedItems[index];
                        return _buildChecklistItem(item, index);
                      },
                    ),
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

  Widget _buildChecklistItem(ChecklistItem item, int index) {
    return Semantics(
      label: "Task: ${item.text}, ${item.isCompleted ? 'Completed' : 'Active'}",
      child: Container(
        key: ValueKey(item.id),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.015),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isCompleted 
                ? Colors.blueAccent.withOpacity(0.05) 
                : Colors.white.withOpacity(0.03),
          ),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          leading: Checkbox(
            value: item.isCompleted,
            onChanged: (_) => widget.onToggle(item),
            activeColor: Colors.blueAccent.withOpacity(0.8),
            checkColor: Colors.black,
            side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          title: Text(
            item.text,
            style: TextStyle(
              fontSize: 14,
              color: item.isCompleted ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.9),
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: Tooltip(
            message: "Delete task",
            child: IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.4), size: 18),
              onPressed: () => widget.onDelete(item.id),
            ),
          ),
        ),
      ),
    );
  }
}
