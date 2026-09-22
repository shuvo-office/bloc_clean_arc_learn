// ═══════════════════════════════════════════════════════════════════════════
// TODO > PRESENTATION > BLOC > STATE
// ═══════════════════════════════════════════════════════════════════════════
// STATE DESIGN: status + data + error, in ONE immutable object.
//
// WHY NOT 4 SEPARATE CLASSES (Loading/Loaded/Error...)?
// ────────────────────────────────────────────────────
// Both styles are valid. This project uses the SINGLE-CLASS + STATUS ENUM
// style because:
//   • Todo screen ALWAYS shows a list (even while refreshing / on error).
//     Separate `TodoError` state would LOSE the old list → blank screen.
//     Single class KEEPS `todos` visible + overlays error as Snackbar.
//   • copyWith() makes transitions one-liners.
// Counter used the minimal style (single int). Real apps use THIS style.
//
// STATUS LIFECYCLE:
//   initial → loading → loaded  (happy path)
//                   ↘ error    (failure path, todos preserved)
// ───────────────────────────────────────────────────────────────────────────
import 'package:equatable/equatable.dart';

import '../../domain/entities/todo.dart';

/// Describes WHAT the screen is doing (not what data it holds).
enum TodoStatus { initial, loading, loaded, error }

class TodoState extends Equatable {
  final TodoStatus status;
  final List<Todo> todos;
  final String errorMessage;

  const TodoState({
    this.status = TodoStatus.initial,
    this.todos = const [],
    this.errorMessage = '',
  });

  // Derived getters — UI reads these, Bloc doesn't store them separately.
  // (Single source of truth: `todos` list. Everything else computed.)
  int get totalCount => todos.length;
  int get doneCount => todos.where((t) => t.isDone).length;
  int get remainingCount => totalCount - doneCount;

  TodoState copyWith({
    TodoStatus? status,
    List<Todo>? todos,
    String? errorMessage,
  }) {
    return TodoState(
      status: status ?? this.status,
      todos: todos ?? this.todos,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [status, todos, errorMessage];
}

// ─── ALTERNATIVE STYLE (commented, for reference) ───────────────────────────
// Sealed-class states — better when screens are MUTUALLY EXCLUSIVE
// (e.g. Login: form XOR loading spinner XOR home screen):
//
//   sealed class TodoState extends Equatable { ... }
//   class TodoInitial extends TodoState {}
//   class TodoLoading extends TodoState {}
//   class TodoLoaded extends TodoState { final List<Todo> todos; ... }
//   class TodoError extends TodoState { final String message; ... }
//
//   // UI: `if (state is TodoLoaded) ... else if (state is TodoError) ...`
// Rule of thumb: list-that-persists → status enum. full-screen swap → sealed.
