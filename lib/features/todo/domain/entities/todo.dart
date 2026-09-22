// ═══════════════════════════════════════════════════════════════════════════
// TODO > DOMAIN > ENTITIES > TODO
// ═══════════════════════════════════════════════════════════════════════════
// LAYER MAP (Clean Architecture = 3 rings, dependency points INWARD):
//
//   ┌─────────────────────────────────────────────┐
//   │ PRESENTATION (UI + Bloc)                    │  ← depends on DOMAIN
//   │   TodoPage, TodoBloc, widgets               │
//   ├─────────────────────────────────────────────┤
//   │ DOMAIN (pure Dart, NO Flutter, NO http)     │  ← depends on NOTHING
//   │   Entity, Repository INTERFACE, UseCases    │  ★ business rules live here
//   ├─────────────────────────────────────────────┤
//   │ DATA (implements DOMAIN contracts)          │  ← depends on DOMAIN
//   │   Model, DataSource, Repository IMPL        │
//   └─────────────────────────────────────────────┘
//
// WHAT IS AN ENTITY?
// ─────────────────
// A plain Dart object with ONLY business meaning. No JSON, no SQL, no API.
//   • Todo(title, isDone) — YES, entity.
//   • TodoModel.fromJson() — NO, that's a MODEL (data layer).
//
// WHY TWO CLASSES (Entity + Model) THAT LOOK IDENTICAL?
// ────────────────────────────────────────────────────
// Because EXTERNAL formats change, BUSINESS meaning doesn't.
//   • Today todos come from memory. Tomorrow from REST, then Firebase.
//   • Entity stays frozen → Bloc + UseCases never change.
//   • Only Model + DataSource change. That's the whole payoff.
//
// GETX/MVC COMPARISON:
//   MVC Model = Entity + Model + Repository SMASHED into one class:
//     class Todo { fromJson(); toJson(); saveToDb(); fetchFromApi(); }
//   Clean Entity = ONLY the data + business helpers (toggle, copyWith).
// ───────────────────────────────────────────────────────────────────────────
import 'package:equatable/equatable.dart';

/// A single todo item — framework-free, testable with plain `dart test`.
class Todo extends Equatable {
  final String id;
  final String title;
  final bool isDone;

  const Todo({
    required this.id,
    required this.title,
    required this.isDone,
  });

  /// Business helper — flipping done-ness belongs HERE (domain),
  /// not in Bloc, not in UI. Any caller gets the same rule.
  Todo toggleDone() => copyWith(isDone: !isDone);

  Todo copyWith({String? id, String? title, bool? isDone}) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  List<Object> get props => [id, title, isDone];
}
