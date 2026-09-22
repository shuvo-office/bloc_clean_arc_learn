// ═══════════════════════════════════════════════════════════════════════════
// TODO > DOMAIN > REPOSITORIES > TODO REPOSITORY (INTERFACE / CONTRACT)
// ═══════════════════════════════════════════════════════════════════════════
// WHAT IS THIS?
// ────────────
// An ABSTRACT class that DECLARES what todo operations exist,
// WITHOUT saying HOW they work. The DATA layer implements it.
//
// WHY AN INTERFACE?
// ────────────────
//   • DOMAIN (Bloc, UseCases) depends on this ABSTRACTION, not on
//     SharedPreferences / http / Firebase. → "Dependency Inversion".
//   • Swap implementations without touching Bloc:
//       TodoRepositoryImpl(local)  →  TodoRepositoryImpl(remote)
//   • Tests inject a FAKE: `FakeTodoRepository()` returns canned data.
//
// READING THE SIGNATURES:
//   Future<Either<Failure, List<Todo>>>
//     │       │         └─ success payload
//     │       └─ error payload (typed Failure, never raw Exception)
//     └─ async (all data operations are Future)
//
// GETX ANALOGY:
//   Like defining `abstract class ApiService { Future getTodos(); }`
//   then `class HttpApiService implements ApiService`.
//   Clean Arch just makes this MANDATORY for every feature.
// ───────────────────────────────────────────────────────────────────────────
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/todo.dart';

abstract class TodoRepository {
  /// Returns ALL todos. Left(CacheFailure) if storage broken.
  Future<Either<Failure, List<Todo>>> getTodos();

  /// Persists a new todo. Left(ValidationFailure) if title blank.
  Future<Either<Failure, Todo>> addTodo(String title);

  /// Flips isDone for [id]. Left(CacheFailure) if id not found.
  Future<Either<Failure, Todo>> toggleTodo(String id);

  /// Removes [id]. Left(CacheFailure) if id not found.
  Future<Either<Failure, void>> deleteTodo(String id);
}
