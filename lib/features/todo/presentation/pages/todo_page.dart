// ═══════════════════════════════════════════════════════════════════════════
// TODO > PRESENTATION > PAGES > TODO PAGE
// ═══════════════════════════════════════════════════════════════════════════
// PUTTING IT TOGETHER: BlocListener (side effects) + BlocBuilder (render).
//
// WIDGET TREE:
//   TodoPage (creates Bloc via get_it, fires initial load)
//    └ _TodoView
//        └ BlocListener (Snackbar on error)
//            └ Column
//                ├ _StatsHeader (done/total counts)
//                ├ AddTodoField (sends TodoAdded)
//                └ Expanded → BlocBuilder (loading | list | empty)
//
// LIFECYCLE:
//   Bloc created → ..add(TodoRequested()) → loading → loaded list.
//   GetX equivalent: Get.put(TodoController()) + onInit(){ fetchTodos(); }
// ───────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../bloc/todo_bloc.dart';
import '../bloc/todo_event.dart';
import '../bloc/todo_state.dart';
import '../widgets/add_todo_field.dart';
import '../widgets/todo_tile.dart';

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // get_it provides the SAME configured Bloc (with all 4 UseCases).
      // `..add(TodoRequested())` = cascade: create THEN immediately load.
      // (GetX equivalent: Get.put(...) + controller.onInit() fetch.)
      create: (_) => di.sl<TodoBloc>()..add(const TodoRequested()),
      child: const _TodoView(),
    );
  }
}

class _TodoView extends StatelessWidget {
  const _TodoView();

  @override
  Widget build(BuildContext context) {
    // ── LISTENER = side effects only (Snackbar, navigation, dialog) ────────
    // listenWhen: only react when status flips TO error (not on every build).
    // Without it, every keystroke-rebuild would re-show the Snackbar.
    return BlocListener<TodoBloc, TodoState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == TodoStatus.error,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red.shade700,
            ),
          );
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Todos — full Clean Arch')),
        body: Column(
          children: [
            // ── STATS HEADER (rebuilds on any state change) ─────────────────
            BlocBuilder<TodoBloc, TodoState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${state.doneCount} of ${state.totalCount} done'
                    ' • ${state.remainingCount} remaining',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              },
            ),
            const AddTodoField(),
            const Divider(height: 1),
            // ── LIST AREA ───────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<TodoBloc, TodoState>(
                builder: (context, state) {
                  // 1. Loading (first fetch) → spinner.
                  if (state.status == TodoStatus.loading &&
                      state.todos.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  // 2. Empty (loaded, zero items) → friendly placeholder.
                  if (state.todos.isEmpty) {
                    return const Center(
                      child: Text(
                        'No todos yet.\nAdd one above 👆',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  // 3. Loaded → the list. Dismissible tiles send events up.
                  return ListView.separated(
                    itemCount: state.todos.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final todo = state.todos[index];
                      return TodoTile(
                        todo: todo,
                        onToggle: () => context
                            .read<TodoBloc>()
                            .add(TodoToggled(todo.id)),
                        onDelete: () => context
                            .read<TodoBloc>()
                            .add(TodoDeleted(todo.id)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CHEAT: BlocConsumer vs Builder+Listener ────────────────────────────────
// Above uses SEPARATE Listener (whole page) + Builders (header, list).
// Alternative: ONE BlocConsumer wrapping Column with both callbacks.
// Separate is better here: header + list rebuild INDEPENDENTLY.
// (If one Builder wrapped everything, typing in AddTodoField's parent
// would rebuild the whole list on every state change — still correct,
// just less efficient. Flutter is fast; prefer readability first.)
