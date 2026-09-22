// ═══════════════════════════════════════════════════════════════════════════
// COUNTER > PRESENTATION > BLOC > BLOC
// ═══════════════════════════════════════════════════════════════════════════
// THE BLOC ITSELF — read this file top-to-bottom, it is the whole pattern.
//
// ANATOMY:
//   class CounterBloc extends Bloc<CounterEvent, CounterState> {
//     CounterBloc() : super(initialState) {
//       on<EventA>((event, emit) { ... });  // handler for EventA
//       on<EventB>((event, emit) { ... });  // handler for EventB
//     }
//   }
//
// `on<E>` REGISTERS a handler. When UI calls `add(E())`, the matching
// handler runs. `emit(...)` pushes a NEW state to all listening widgets.
//
// ─── TRACE ONE BUTTON PRESS ───────────────────────────────────────────────
//   1. User taps "+" → UI: `context.read<CounterBloc>().add(CounterIncremented())`
//   2. Bloc finds `on<CounterIncremented>` handler below.
//   3. Handler: `emit(state.copyWith(count: state.count + 1))`
//      - `state` = CURRENT snapshot (e.g. count: 4)
//      - `emit`  = publish NEW snapshot (count: 5)
//   4. BlocBuilder sees new state ≠ old state (Equatable props differ)
//      → calls builder() again → Text shows "5".
//
// ─── GETX EQUIVALENT (for your muscle memory) ─────────────────────────────
//   class CounterController extends GetxController {
//     var count = 0.obs;
//     void increment() => count.value++;   // mutate + notify
//   }
//   // Bloc splits that ONE method into TWO halves:
//   //   Event  = "increment was requested"   (the intent)
//   //   on<>   = "here is what increment MEANS" (the logic)
//   // This split is what makes Bloc testable WITHOUT widgets.
// ───────────────────────────────────────────────────────────────────────────
import 'package:flutter_bloc/flutter_bloc.dart';

import 'counter_event.dart';
import 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterState.initial) {
    // ── Handler 1: increment ──────────────────────────────────────────────
    // `event` = the CounterIncremented() object (no data inside this time).
    // `emit`  = function that publishes new state. Call it ONCE per event
    //           (or zero times if event changes nothing).
    on<CounterIncremented>((event, emit) {
      // NEVER do: state.count++  → states are immutable!
      // ALWAYS emit a fresh object:
      emit(state.copyWith(count: state.count + 1));
    });

    // ── Handler 2: decrement ──────────────────────────────────────────────
    on<CounterDecremented>((event, emit) {
      emit(state.copyWith(count: state.count - 1));
    });

    // ── Handler 3: reset ──────────────────────────────────────────────────
    on<CounterReset>((event, emit) {
      // Emit the shared initial constant — same object every reset.
      // Equatable sees count 0 == 0 → if already 0, NO rebuild. Efficient!
      emit(CounterState.initial);
    });

    // ─── WHERE DOES ASYNC GO? ─────────────────────────────────────────────
    // If increment needed a server call, handler becomes async:
    //   on<CounterIncremented>((event, emit) async {
    //     emit(CounterLoading());
    //     try { final v = await repo.get(); emit(CounterLoaded(v)); }
    //     catch (e) { emit(CounterError(e.toString())); }
    //   });
    // See TodoBloc for the full async + Either<Failure,...> version.
  }

  // ─── DEBUGGING HOOK (optional, uncomment to use) ─────────────────────────
  // @override
  // void onChange(Change<CounterState> change) {
  //   super.onChange(change);
  //   // Fires on EVERY emit. Like GetX `ever()` / `everAll()` but built-in.
  //   // print('CHANGE: ${change.currentState.count} → ${change.nextState.count}');
  // }
  //
  // @override
  // void onError(Object error, StackTrace stackTrace) {
  //   super.onError(error, stackTrace);
  //   // Fires on uncaught handler errors. Log to Crashlytics here.
  // }
}
