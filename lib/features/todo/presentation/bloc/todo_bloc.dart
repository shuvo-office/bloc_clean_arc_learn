// ═══════════════════════════════════════════════════════════════════════════
// TODO > PRESENTATION > BLOC > BLOC
// ═══════════════════════════════════════════════════════════════════════════
// THE FULL ASYNC PATTERN — every real-world Bloc looks like this:
//
//   on<Event>((event, emit) async {
//     emit(state.copyWith(status: loading));      // 1. optimistic loading
//     final result = await usecase(params);       // 2. run business logic
//     result.fold(
//       (failure) => emit(state.copyWith(      // 3a. error path
//           status: error, errorMessage: failure.message)),
//       (data) => emit(state.copyWith(         // 3b. success path
//           status: loaded, todos: updatedList)),
//     );
//   });
//
// `fold` = Either's if/else: first callback handles Left, second Right.
// You CANNOT forget the error branch — compiler forces both. That's why
// Clean Arch uses Either instead of try/catch (which you CAN forget).
//
// OPTIMISTIC vs PESSIMISTIC updates:
//   • Below: PESSIMISTIC for add/toggle/delete — we re-fetch / patch list
//     only AFTER usecase succeeds. UI never shows unconfirmed data.
//   • OPTIMISTIC (show instantly, rollback on fail) is faster UX but needs
//     rollback code. Uncomment the optimistic snippet in _onToggled to try.
// ───────────────────────────────────────────────────────────────────────────
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/todo_usecases.dart';
import '../../../../core/usecases/usecase.dart';
import 'todo_event.dart';
import 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  // UseCases injected via constructor (get_it wires them in main).
  // Bloc knows INTERFACES (UseCase), never DataSource / http details.
  final GetTodos getTodos;
  final AddTodo addTodo;
  final ToggleTodo toggleTodo;
  final DeleteTodo deleteTodo;

  TodoBloc({
    required this.getTodos,
    required this.addTodo,
    required this.toggleTodo,
    required this.deleteTodo,
  }) : super(const TodoState()) {
    on<TodoRequested>(_onRequested);
    on<TodoAdded>(_onAdded);
    on<TodoToggled>(_onToggled);
    on<TodoDeleted>(_onDeleted);
  }

  // ── 1. LOAD ───────────────────────────────────────────────────────────────
  Future<void> _onRequested(
    TodoRequested event,
    Emitter<TodoState> emit,
  ) async {
    emit(state.copyWith(status: TodoStatus.loading));
    final result = await getTodos(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: TodoStatus.error,
        errorMessage: failure.message,
      )),
      (todos) => emit(state.copyWith(
        status: TodoStatus.loaded,
        todos: todos,
      )),
    );
  }

  // ── 2. ADD ────────────────────────────────────────────────────────────────
  Future<void> _onAdded(TodoAdded event, Emitter<TodoState> emit) async {
    final result = await addTodo(AddTodoParams(event.title));
    result.fold(
      // ValidationFailure (empty title) lands here → Snackbar via Listener.
      (failure) => emit(state.copyWith(
        status: TodoStatus.error,
        errorMessage: failure.message,
      )),
      // Success: append to EXISTING list (no re-fetch needed).
      // `[...state.todos, todo]` = new list (immutable update!).
      (todo) => emit(state.copyWith(
        status: TodoStatus.loaded,
        todos: [...state.todos, todo],
      )),
    );
  }

  // ── 3. TOGGLE ─────────────────────────────────────────────────────────────
  Future<void> _onToggled(TodoToggled event, Emitter<TodoState> emit) async {
    final result = await toggleTodo(ToggleTodoParams(event.id));
    result.fold(
      (failure) => emit(state.copyWith(
        status: TodoStatus.error,
        errorMessage: failure.message,
      )),
      (updated) {
        // Replace ONLY the changed item (map = immutable list update).
        final next = state.todos
            .map((t) => t.id == updated.id ? updated : t)
            .toList();
        emit(state.copyWith(status: TodoStatus.loaded, todos: next));
      },
    );

    // ── OPTIMISTIC VARIANT (uncomment to experiment) ─────────────────────
    // final previous = state.todos;
    // emit(state.copyWith(
    //   status: TodoStatus.loaded,
    //   todos: previous.map((t) =>
    //     t.id == event.id ? t.toggleDone() : t).toList(),
    // ));
    // final result = await toggleTodo(ToggleTodoParams(event.id));
    // result.fold(
    //   (_) => emit(state.copyWith( // rollback on failure
    //     status: TodoStatus.error, todos: previous,
    //     errorMessage: 'Could not update')),
    //   (_) {}, // already showing correct UI, nothing to do
    // );
  }

  // ── 4. DELETE ─────────────────────────────────────────────────────────────
  Future<void> _onDeleted(TodoDeleted event, Emitter<TodoState> emit) async {
    final result = await deleteTodo(DeleteTodoParams(event.id));
    result.fold(
      (failure) => emit(state.copyWith(
        status: TodoStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final next = state.todos.where((t) => t.id != event.id).toList();
        emit(state.copyWith(status: TodoStatus.loaded, todos: next));
      },
    );
  }
}

// ─── GETX TRANSLATION TABLE (tape this to your monitor) ─────────────────────
//   GetX Controller                 │  BLoC equivalent
//   ────────────────────────────────┼─────────────────────────────────────
//   var todos = <Todo>[].obs;       │  TodoState(todos: [...])
//   todos.add(x); update();         │  emit(state.copyWith(todos: [...]))
//   isLoading.value = true;         │  emit(state.copyWith(status: loading))
//   try/catch + snackbar in method  │  fold(Left→error state, Right→loaded)
//   onInit(){ fetchTodos(); }       │  add(TodoRequested()) from UI init
//   ever(todos, (_) => save());     │  BlocListener / BlocObserver
