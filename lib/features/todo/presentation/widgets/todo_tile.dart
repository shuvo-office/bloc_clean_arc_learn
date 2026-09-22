// ═══════════════════════════════════════════════════════════════════════════
// TODO > PRESENTATION > WIDGETS > TODO TILE
// ═══════════════════════════════════════════════════════════════════════════
// DUMB WIDGET #2: renders ONE Todo row. All callbacks = Events sent upward.
// No Bloc access inside (receives `todo` + callbacks via constructor) →
// reusable in ANY parent, testable with plain widget test (no Bloc needed).
import 'package:flutter/material.dart';

import '../../domain/entities/todo.dart';

class TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      // Swipe-to-delete UX. onDismissed → parent sends TodoDeleted event.
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Checkbox(
          value: todo.isDone,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            // Business state (isDone) → visual style. Pure mapping, no logic.
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
            color: todo.isDone ? Colors.grey : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        onTap: onToggle,
      ),
    );
  }
}
