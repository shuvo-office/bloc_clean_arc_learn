// ═══════════════════════════════════════════════════════════════════════════
// COUNTER > PRESENTATION > BLOC > STATE
// ═══════════════════════════════════════════════════════════════════════════
// WHAT IS STATE?
// ─────────────
// A snapshot of "what the screen should show RIGHT NOW".
// The Bloc EMITS new snapshots; the UI REBUILDS from them.
//
// RULES (strict in BLoC, loose in GetX):
//   1. IMMUTABLE — fields are `final`, never `count++` a state object.
//      You always create a NEW state: `emit(CounterState(count + 1))`.
//   2. COMPARABLE — extend Equatable + list fields in `props`,
//      so BlocBuilder can skip rebuilds when NOTHING actually changed.
//   3. UI-DRIVEN — name states by what UI shows, not by what happened:
//      ✅ CounterLoading, CounterLoaded(todos), CounterError(message)
//      ❌ CounterButtonClicked (that's an EVENT name, not a state)
//
// GETX COMPARISON:
//   GetX:  RxInt count = 0.obs;  → MUTABLE variable, UI watches it.
//   BLoC:  CounterState(count: 0) → IMMUTABLE snapshot, UI receives copies.
// ───────────────────────────────────────────────────────────────────────────
import 'package:equatable/equatable.dart';

/// The ENTIRE UI state of the counter screen fits in ONE int.
///
/// Bigger screens have bigger states:
///   TodoState(status: loading|loaded|error, todos: [...], filter: all|done)
/// but the principle is identical: ONE object describes the WHOLE screen.
class CounterState extends Equatable {
  final int count;

  const CounterState(this.count);

  // Initial state — what the screen shows BEFORE any event arrives.
  // CounterBloc calls super(const CounterState(0)).
  static const initial = CounterState(0);

  @override
  List<Object> get props => [count];

  // ── OPTIONAL HELPER ──────────────────────────────────────────────────────
  // `copyWith` lets you clone a state changing only SOME fields:
  //   emit(state.copyWith(count: state.count + 1))
  // For a single-field state it's overkill, but keep the pattern —
  // you'll use it in EVERY real feature (see TodoState).
  CounterState copyWith({int? count}) {
    return CounterState(count ?? this.count);
  }
}
