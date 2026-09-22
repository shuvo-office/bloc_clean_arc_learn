// CounterBloc unit test — pure Dart, no widgets, no DI, no network.
// Run: flutter test
// Teaching point: Bloc logic is testable WITHOUT pumping widgets.
// (Compare: GetX controller tests need Get.testMode + widget bindings.)
import 'package:bloc_clean_arc_learn/features/counter/presentation/bloc/counter_bloc.dart';
import 'package:bloc_clean_arc_learn/features/counter/presentation/bloc/counter_event.dart';
import 'package:bloc_clean_arc_learn/features/counter/presentation/bloc/counter_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CounterBloc', () {
    test('initial state is count 0', () {
      expect(CounterBloc().state, const CounterState(0));
    });

    test('Increment x2 → Decrement → Reset emits 1, 2, 1, 0', () async {
      final bloc = CounterBloc();
      // Collect emitted states: expectLater listens BEFORE events are added.
      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          const CounterState(1),
          const CounterState(2),
          const CounterState(1),
          CounterState.initial, // 0 — differs from 1, so it IS emitted
        ]),
      );
      bloc
        ..add(const CounterIncremented())
        ..add(const CounterIncremented())
        ..add(const CounterDecremented())
        ..add(const CounterReset());
      await future;
      await bloc.close();
    });

    // ── Equatable dedup: a state EQUAL to current is suppressed ───────────────
    // Bloc rule (see bloc package bloc_base.dart):
    //   if (state == _state && _emitted) return;   // skip duplicate
    // The FIRST emit always goes through (_emitted starts false), so:
    //   Increment (0→1) emits, Decrement (1→0) emits, Reset (0→0) SKIPPED.
    // This is why BlocBuilder skips pointless rebuilds (see counter_state.dart).
    test('Reset back to current count emits nothing (Equatable dedup)',
        () async {
      final bloc = CounterBloc();
      final future = expectLater(
        bloc.stream,
        emitsInOrder([
          const CounterState(1),
          const CounterState(0),
          emitsDone, // Reset adds nothing → stream closes cleanly
        ]),
      );
      bloc
        ..add(const CounterIncremented())
        ..add(const CounterDecremented())
        ..add(const CounterReset()); // 0 → 0: suppressed, no emission
      // Decrement's emission may arrive after Reset is processed; give the
      // queue a beat, then close (close flushes pending events first).
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await bloc.close();
      await future;
    });
  });
}
