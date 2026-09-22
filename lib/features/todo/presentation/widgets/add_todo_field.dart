// ═══════════════════════════════════════════════════════════════════════════
// TODO > PRESENTATION > WIDGETS > ADD TODO FIELD
// ═══════════════════════════════════════════════════════════════════════════
// DUMB WIDGET: owns a TextEditingController, sends ONE event on submit,
// owns ZERO business state. Validation lives in AddTodo UseCase;
// empty-title error comes BACK as TodoState.error → parent shows Snackbar.
//
// GetX comparison:
//   GetX: TextField + controller in Controller, onChanged updates RxString.
//   BLoC: TextField is LOCAL (controller here), submit sends TodoAdded event.
//         No reactive variable for the draft text — it doesn't need to be
//         shared, so it stays private to the widget. Less global state!
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/todo_bloc.dart';
import '../bloc/todo_event.dart';

class AddTodoField extends StatefulWidget {
  const AddTodoField({super.key});

  @override
  State<AddTodoField> createState() => _AddTodoFieldState();
}

class _AddTodoFieldState extends State<AddTodoField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text;
    // Don't pre-validate here — let the UseCase decide (single rule source).
    // We only guard whitespace-only to avoid useless Bloc round-trips... actually
    // even that is optional; sending it demonstrates ValidationFailure path.
    // Try submitting empty text to SEE the error Snackbar!
    context.read<TodoBloc>().add(TodoAdded(text));
    _controller.clear();
    // Keep keyboard open for rapid entry (UX nicety).
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'What needs doing? (try empty → see validation)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _submit,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
