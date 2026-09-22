// ═══════════════════════════════════════════════════════════════════════════
// CORE > USECASES > USECASE
// ═══════════════════════════════════════════════════════════════════════════
// WHAT IS A USECASE?
// ─────────────────
// A UseCase = ONE business rule / ONE user intention.
//   "Get all todos", "Add a todo", "Login user" — each is ONE UseCase class.
//
// WHY NOT JUST CALL REPOSITORY DIRECTLY FROM BLOC?
// ────────────────────────────────────────────────
// You CAN — and for tiny apps it's fine. But UseCases give you:
//   1. Single Responsibility: Bloc handles STATE, UseCase handles LOGIC.
//   2. Reusability: Same UseCase callable from 2 different Blocs.
//   3. Testability: Test business rule WITHOUT widget or Bloc.
//   4. Self-documentation: `lib/.../domain/usecases/` IS your feature list.
//
// GETX ANALOGY (you know this):
// ─────────────────────────────
//   GetX Controller method:
//     void addTodo(String title) { todos.add(Todo(title)); }
//
//   Clean Arch split:
//     AddTodo usecase  = the `todos.add(...)` LOGIC part
//     TodoBloc         = the `update()` / `.obs` STATE part
//
// HOW TO READ THIS FILE:
//   `call()` makes the object callable like a function:
//     final result = await getTodos(NoParams());
//   instead of:
//     final result = await getTodos.execute(NoParams());
//
//   `Either<Failure, Success>` = functional error handling (from dartz package):
//     Left(Failure)  → error path — Bloc emits Error state
//     Right(Data)    → success path — Bloc emits Loaded state
// ───────────────────────────────────────────────────────────────────────────
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Every UseCase in the app implements this interface.
///
/// [Success] = what it RETURNS on success (e.g. List<Todo>, Todo, void)
/// [Params] = what it NEEDS as input (e.g. AddTodoParams, NoParams)
///
/// Example:
/// ```dart
/// class GetTodos extends UseCase<List<Todo>, NoParams> {
///   @override
///   Future<Either<Failure, List<Todo>>> call(NoParams params) { ... }
/// }
/// ```
abstract class UseCase<Success, Params> {
  Future<Either<Failure, Success>> call(Params params);
}

/// Use this when a UseCase takes NO input.
/// Instead of passing `null` (which is ambiguous), pass `NoParams()`.
///
/// Why a class and not `void`?
/// Because `UseCase<Type, void>` gets messy with null-safety.
/// `NoParams()` is explicit: "I consciously pass nothing."
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
