// ═══════════════════════════════════════════════════════════════════════════
// TODO > DATA > REPOSITORIES > TODO REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════
// THE BRIDGE between DATA and DOMAIN.
//
// JOB (exactly 2 things, nothing else):
//   1. Call DataSource (which throws Exceptions).
//   2. Convert result → Entity and wrap in Either:
//        success → Right(entity)
//        failure → Left(Failure)
//
// WHY THIS INDIRECTION?
//   DOMAIN speaks: Either<Failure, Entity>   (typed, functional)
//   DATA speaks:  Model + Exceptions         (raw, imperative)
//   RepositoryImpl is the TRANSLATOR. Bloc/UseCases never see Exceptions;
//   DataSources never see Failures. Clean boundary.
//
// ERROR MAPPING CHEAT SHEET (memorize):
//   CacheException   → CacheFailure
//   ServerException  → ServerFailure
//   FormatException  → ValidationFailure (bad JSON shape)
//   anything else    → UnexpectedFailure
// ───────────────────────────────────────────────────────────────────────────
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/todo_local_datasource.dart';

class TodoRepositoryImpl implements TodoRepository {
  final TodoLocalDataSource localDataSource;

  // DataSource injected → test can pass a fake that throws on demand.
  TodoRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Todo>>> getTodos() async {
    try {
      final models = await localDataSource.getTodos();
      // TodoModel EXTENDS Todo, so List<TodoModel> IS List<Todo>. No mapping.
      // If they differed, you'd map: models.map((m) => m.toEntity()).toList()
      return Right(models);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      // Never let raw exceptions leak to DOMAIN.
      return const Left(UnexpectedFailure('Failed to load todos'));
    }
  }

  @override
  Future<Either<Failure, Todo>> addTodo(String title) async {
    try {
      final model = await localDataSource.addTodo(title);
      return Right(model);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure('Failed to add todo'));
    }
  }

  @override
  Future<Either<Failure, Todo>> toggleTodo(String id) async {
    try {
      final model = await localDataSource.toggleTodo(id);
      return Right(model);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure('Failed to update todo'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTodo(String id) async {
    try {
      await localDataSource.deleteTodo(id);
      // Right(null) doesn't compile with null-safety → use Right(null) via:
      // ignore: void_checks (or return const Right(null) in older dartz)
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure('Failed to delete todo'));
    }
  }
}
