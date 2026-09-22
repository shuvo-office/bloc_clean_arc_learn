// ═══════════════════════════════════════════════════════════════════════════
// TODO > PRESENTATION > BLOC > EVENT
// ═══════════════════════════════════════════════════════════════════════════
// EVENTS = user intentions + lifecycle triggers.
// Naming: past tense / imperative describing WHAT HAPPENED, not what to do:
//   ✅ TodoRequested  (page opened, "give me data")
//   ✅ TodoAdded(title) (user submitted the text field)
//   ✅ TodoToggled(id)  (user tapped checkbox)
//   ✅ TodoDeleted(id)  (user swiped to dismiss)
//
// DESIGN RULE: one Event per USER ACTION, carrying ONLY the data the
// Bloc needs (id, title). NEVER pass BuildContext, controllers, or widgets
// inside events — Bloc must stay UI-framework-independent (testable).
// ───────────────────────────────────────────────────────────────────────────
import 'package:equatable/equatable.dart';

sealed class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object> get props => [];
}

/// Fired once when TodoPage opens (like GetX onInit / onReady fetch).
class TodoRequested extends TodoEvent {
  const TodoRequested();
}

/// Fired when user submits the "add" text field.
class TodoAdded extends TodoEvent {
  final String title;
  const TodoAdded(this.title);

  @override
  List<Object> get props => [title];
}

/// Fired when user taps a checkbox / tile.
class TodoToggled extends TodoEvent {
  final String id;
  const TodoToggled(this.id);

  @override
  List<Object> get props => [id];
}

/// Fired when user swipes-to-dismiss or taps delete icon.
class TodoDeleted extends TodoEvent {
  final String id;
  const TodoDeleted(this.id);

  @override
  List<Object> get props => [id];
}
