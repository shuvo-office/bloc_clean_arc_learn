// ═══════════════════════════════════════════════════════════════════════════
// COUNTER > PRESENTATION > BLOC > EVENT
// ═══════════════════════════════════════════════════════════════════════════
// BLoC MENTAL MODEL (memorize this):
// ──────────────────────────────────
//   EVENT  = "something happened" (user tapped +, - , reset)
//            INPUT to the Bloc. Past tense is a good naming hint.
//   STATE  = "how the UI should look right now" (count = 5)
//            OUTPUT from the Bloc. UI just renders it, no logic.
//   BLOC   = "when EVENT X arrives and current STATE is Y, emit STATE Z"
//            Pure function: (Event + State) → New State.
//
// FLOW (one-way, always the same):
//   UI --add(Event)--> BLOC --emit(State)--> UI rebuilds
//        ▲                                        │
//        └────────── user sees new UI ────────────┘
//
// GETX vs BLOC — SAME COUNTER, DIFFERENT PHILOSOPHY:
// ─────────────────────────────────────────────────
//   GetX:
//     controller.count.value++   // mutate observable directly
//     Obx(() => Text("${controller.count}"))  // UI watches variable
//
//   BLoC:
//     context.read<CounterBloc>().add(CounterIncremented()) // send INTENT
//     BlocBuilder<CounterBloc, CounterState>(builder: ... ) // UI renders STATE
//
//   KEY DIFFERENCE:
//   • GetX: UI tells CONTROLLER what to DO ("increment!")
//           Controller mutates shared variable, everyone watching rebuilds.
//   • BLoC: UI tells BLOC what HAPPENED ("increment button pressed")
//           Bloc decides NEW STATE, emits it, UI rebuilds from scratch.
//           Old states are GONE (immutable) — you can log/replay/debug them.
// ───────────────────────────────────────────────────────────────────────────
import 'package:equatable/equatable.dart';

/// Base class for all counter events.
/// `sealed` = Dart 3 keyword: no other file can add new subclasses.
/// This lets the compiler WARN you if your Bloc forgets to handle an event.
sealed class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object> get props => [];
}

/// User tapped the "+" button.
class CounterIncremented extends CounterEvent {
  const CounterIncremented();
}

/// User tapped the "−" button.
class CounterDecremented extends CounterEvent {
  const CounterDecremented();
}

/// User tapped the reset icon.
class CounterReset extends CounterEvent {
  const CounterReset();
}

// ─── INTERVIEW / EXAM NOTE ──────────────────────────────────────────────────
// Q: "Why not just pass an int, or call bloc.increment() directly?"
// A: Events are OBJECTS, so they can carry data + be logged + be tested:
//      class CounterSetTo extends CounterEvent { final int value; ... }
//    A method call `bloc.increment()` is invisible to DevTools.
//    An event object `CounterIncremented()` shows up in BlocObserver logs,
//    can be replayed for time-travel debugging, and unit-tested in isolation.
