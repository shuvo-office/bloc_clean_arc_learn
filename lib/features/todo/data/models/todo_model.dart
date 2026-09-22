// ═══════════════════════════════════════════════════════════════════════════
// TODO > DATA > MODELS > TODO MODEL
// ═══════════════════════════════════════════════════════════════════════════
// MODEL vs ENTITY (the #1 confusion for GetX migrants):
//
//   ENTITY (domain/entities/todo.dart)
//     • Pure business object. Knows NOTHING about JSON, SQL, http.
//     • Used by Bloc, UseCases, UI.
//
//   MODEL (this file)
//     • EXTENDS Entity + adds SERIALIZATION (fromJson/toJson, fromMap...).
//     • Used ONLY inside DATA layer (DataSource, RepositoryImpl).
//     • RepositoryImpl converts Model → Entity before returning UP.
//       (so DOMAIN never sees JSON keys, snake_case, _id quirks, etc.)
//
// WHY EXTEND INSTEAD OF DUPLICATE?
//   `class TodoModel extends Todo` inherits id/title/isDone + Equatable,
//   so a Model IS-A Todo anywhere an Entity is expected. Zero mapping code
//   for identical shapes; override mapping only when API differs.
// ───────────────────────────────────────────────────────────────────────────
import '../../domain/entities/todo.dart';

class TodoModel extends Todo {
  const TodoModel({
    required super.id,
    required super.title,
    required super.isDone,
  });

  /// DATA → DOMAIN: parse external map into a Model.
  /// If API uses different keys (e.g. `is_completed`), ONLY this changes.
  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      // `?? false` = defensive default if backend omits the field.
      isDone: json['isDone'] as bool? ?? false,
    );
  }

  /// DOMAIN → DATA: serialize for storage / API.
  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'isDone': isDone};
  }

  /// Clone an Entity into a Model (used by RepositoryImpl).
  factory TodoModel.fromEntity(Todo todo) {
    return TodoModel(id: todo.id, title: todo.title, isDone: todo.isDone);
  }

  // ─── UNCOMMENT WHEN YOU ADD A REAL API ────────────────────────────────────
  // Real projects often need TWO models (remote vs cache):
  //   TodoRemoteModel.fromJson(apiJson)  // keys: _id, task_name, completed
  //   TodoCacheModel.fromMap(dbRow)      // keys: id, title, is_done (snake)
  // Both extend Todo. RepositoryImpl picks source based on connectivity.
}

// ─── CHEAT SHEET ────────────────────────────────────────────────────────────
// GetX MVC:  Todo.fromJson(json) directly in Controller.
//            API key rename → Controller + UI both break.
// Clean:    TodoModel.fromJson(json) in DATA layer only.
//            API key rename → edit THIS file, Bloc/UI untouched.
