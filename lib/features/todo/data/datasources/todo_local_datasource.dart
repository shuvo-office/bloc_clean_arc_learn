// ═══════════════════════════════════════════════════════════════════════════
// TODO > DATA > DATASOURCES > TODO LOCAL DATASOURCE
// ═══════════════════════════════════════════════════════════════════════════
// WHAT IS A DATASOURCE?
// ────────────────────
// The ONLY class allowed to touch the outside world:
//   • LocalDataSource  → SharedPreferences, SQLite, Hive, files, memory.
//   • RemoteDataSource → http, Dio, Firebase, gRPC.
//
// RULES:
//   1. Works with MODELS, not Entities (see TodoModel).
//   2. THROWS Exceptions (not Failures!) — RepositoryImpl catches them
//      and converts to Left(Failure). Failures live in DOMAIN;
//      Exceptions live in DATA. Never mix them.
//   3. Has NO business logic — dumb CRUD only.
//
// THIS LEARNING PROJECT:
//   In-memory Map = fake "database" so app runs with ZERO setup.
//   Swap this ONE class for SharedPreferences later; everything above
//   (Repository, UseCases, Bloc, UI) stays IDENTICAL. That's Clean Arch.
//
// GETX ANALOGY:
//   Like your `ApiService` / `DbHelper` class, but SPLIT per source
//   (local vs remote) instead of one god-class doing everything.
// ───────────────────────────────────────────────────────────────────────────
import '../models/todo_model.dart';

/// Thrown ONLY inside data layer. RepositoryImpl catches → CacheFailure.
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);
}

abstract class TodoLocalDataSource {
  Future<List<TodoModel>> getTodos();
  Future<TodoModel> addTodo(String title);
  Future<TodoModel> toggleTodo(String id);
  Future<void> deleteTodo(String id);
}

class TodoLocalDataSourceImpl implements TodoLocalDataSource {
  // ── FAKE DATABASE ─────────────────────────────────────────────────────────
  // In real app: SharedPreferences.getStringList / Hive box / SQLite table.
  // Keyed by id for O(1) toggle/delete (vs List.indexWhere each time).
  final Map<String, TodoModel> _store = {};

  // Simple id generator. Real app: uuid package or backend id.
  int _autoIncrement = 0;

  // Seed with 2 items so first launch isn't an empty screen.
  TodoLocalDataSourceImpl() {
    _seed();
  }

  void _seed() {
    const seeds = [
      TodoModel(id: 'seed-1', title: 'Learn Bloc Event → State', isDone: true),
      TodoModel(id: 'seed-2', title: 'Learn Clean Architecture layers', isDone: false),
    ];
    for (final t in seeds) {
      _store[t.id] = t;
    }
    _autoIncrement = 100; // avoid colliding with seed ids
  }

  @override
  Future<List<TodoModel>> getTodos() async {
    // Simulate latency so Loading state is VISIBLE (remove in real local db).
    await Future.delayed(const Duration(milliseconds: 400));
    // Return a COPY — callers can't mutate our internal store.
    return _store.values.toList();
  }

  @override
  Future<TodoModel> addTodo(String title) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final todo = TodoModel(
      id: 'local-${_autoIncrement++}',
      title: title,
      isDone: false,
    );
    _store[todo.id] = todo;
    return todo;
  }

  @override
  Future<TodoModel> toggleTodo(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final existing = _store[id];
    if (existing == null) {
      // ← RepositoryImpl catches this → Left(CacheFailure('not found'))
      // NOTE: NOT const — message contains runtime $id interpolation.
      throw CacheException('Todo not found: $id');
    }
    final updated = TodoModel(
      id: existing.id,
      title: existing.title,
      isDone: !existing.isDone,
    );
    _store[id] = updated;
    return updated;
  }

  @override
  Future<void> deleteTodo(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!_store.containsKey(id)) {
      throw CacheException('Todo not found: $id');
    }
    _store.remove(id);
  }
}

// ─── WHEN YOU ADD HTTP LATER (template, keep commented) ─────────────────────
// abstract class TodoRemoteDataSource {
//   Future<List<TodoModel>> getTodos();   // GET /todos
//   Future<TodoModel> addTodo(String t);  // POST /todos
// }
// class TodoRemoteDataSourceImpl implements TodoRemoteDataSource {
//   final http.Client client;             // injected via get_it
//   TodoRemoteDataSourceImpl(this.client);
//   @override
//   Future<List<TodoModel>> getTodos() async {
//     final res = await client.get(Uri.parse('https://api.../todos'));
//     if (res.statusCode != 200) throw ServerException();
//     return (json.decode(res.body) as List).map((e) => TodoModel.fromJson(e)).toList();
//   }
//   ...
// }
