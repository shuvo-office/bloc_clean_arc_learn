// ═══════════════════════════════════════════════════════════════════════════
// TODO > DOMAIN > USECASES
// ═══════════════════════════════════════════════════════════════════════════
// ONE FILE PER USECASE is the convention (GetTodos, AddTodo, ...).
// Kept in ONE file here so you can compare all four side-by-side while
// learning. Split them when the project grows.
//
// WHAT EACH USECASE DOES:
//   1. Receives typed Params (or NoParams).
//   2. Calls ONE repository method. (UseCases orchestrate, never store data.)
//   3. Returns Either<Failure, Result> untouched — Bloc decides the UI state.
//
// WHERE DOES VALIDATION LIVE?
//   • Trivial checks (empty title) → inside UseCase (see AddTodo).
//   • Complex rules (max 100 todos) → also UseCase, BEFORE hitting repo.
//   • Format checks (email regex) → UI TextFormField validator (fail fast).
//
// naming: <Verb><Noun> — GetTodos, AddTodo, ToggleTodo, DeleteTodo.
// ───────────────────────────────────────────────────────────────────────────
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

// ═══════════════ 1. GET TODOS ═══════════════
class GetTodos extends UseCase<List<Todo>, NoParams> {
  final TodoRepository repository;

  // Repository is INJECTED (via get_it), not `new`-ed.
  // → test can pass FakeTodoRepository() here.
  GetTodos(this.repository);

  @override
  Future<Either<Failure, List<Todo>>> call(NoParams params) {
    // No logic — pure delegation. Still valuable as documentation
    // ("this feature CAN list todos") + seam for future rules (sorting...).
    return repository.getTodos();
  }
}

// ═══════════════ 2. ADD TODO ═══════════════
/// Params object — bundles inputs so `call()` always takes ONE argument.
/// Why not `call(String title)`? Because UseCase<Type, Params> demands ONE
/// type; Params class scales to 5 fields without changing the interface.
class AddTodoParams extends Equatable {
  final String title;
  const AddTodoParams(this.title);

  @override
  List<Object> get props => [title];
}

class AddTodo extends UseCase<Todo, AddTodoParams> {
  final TodoRepository repository;
  AddTodo(this.repository);

  @override
  Future<Either<Failure, Todo>> call(AddTodoParams params) async {
    // ── DOMAIN-LEVEL VALIDATION ─────────────────────────────────────────
    // GetX equivalent: `if (title.isEmpty) { snackbar("required"); return; }`
    // Clean equivalent: return Left(ValidationFailure) → Bloc emits Error.
    // UI stays dumb: it just renders whatever state the Bloc emits.
    if (params.title.trim().isEmpty) {
      return const Left(ValidationFailure('Title cannot be empty'));
    }
    return repository.addTodo(params.title.trim());
  }
}

// ═══════════════ 3. TOGGLE TODO ═══════════════
class ToggleTodoParams extends Equatable {
  final String id;
  const ToggleTodoParams(this.id);

  @override
  List<Object> get props => [id];
}

class ToggleTodo extends UseCase<Todo, ToggleTodoParams> {
  final TodoRepository repository;
  ToggleTodo(this.repository);

  @override
  Future<Either<Failure, Todo>> call(ToggleTodoParams params) {
    return repository.toggleTodo(params.id);
  }
}

// ═══════════════ 4. DELETE TODO ═══════════════
class DeleteTodoParams extends Equatable {
  final String id;
  const DeleteTodoParams(this.id);

  @override
  List<Object> get props => [id];
}

class DeleteTodo extends UseCase<void, DeleteTodoParams> {
  final TodoRepository repository;
  DeleteTodo(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteTodoParams params) {
    return repository.deleteTodo(params.id);
  }
}
