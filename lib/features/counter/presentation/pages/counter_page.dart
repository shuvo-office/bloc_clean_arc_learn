// ═══════════════════════════════════════════════════════════════════════════
// COUNTER > PRESENTATION > PAGES > COUNTER PAGE
// ═══════════════════════════════════════════════════════════════════════════
// HOW UI TALKS TO BLOC — only 3 widgets / methods to memorize:
//
//   1. context.read<CounterBloc>().add(Event())
//      → SEND an event (fire-and-forget). Use inside onPressed, onTap.
//      → `read` = "give me the Bloc once, I won't rebuild when it changes."
//
//   2. BlocBuilder<CounterBloc, CounterState>(builder: (context, state) {...})
//      → REBUILD part of UI when state changes. Like Obx() in GetX.
//      → Return widgets based on `state`. NO side effects here (no Snackbar!).
//
//   3. BlocListener<CounterBloc, CounterState>(listener: (context, state) {...})
//      → RUN side effects (Snackbar, navigation, dialog) on state change.
//      → Returns NO widget. Like `ever()` worker in GetX.
//
//   4. BlocConsumer = Builder + Listener in one (convenience).
//
// GOLDEN RULE:
//   builder = PURE (maps state → widgets)
//   listener = IMPURE (navigation, toast, vibration, analytics)
// ───────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/counter_bloc.dart';
import '../bloc/counter_event.dart';
import '../bloc/counter_state.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ── BlocProvider CREATES + PROVIDES the Bloc to this subtree ──────────
    // GetX equivalent: Get.put(CounterController()) on this screen.
    // Difference: Provider AUTO-DISPOSES the Bloc when page is popped.
    // (GetX needs Get.delete() or SmartManagement to do the same.)
    return BlocProvider(
      create: (_) => CounterBloc(),
      child: const _CounterView(),
    );
  }
}

/// Separated so `context.read/watch` inside finds the Provider ABOVE it.
/// (If _CounterView were inline in CounterPage.build, `read` would fail
/// because Provider is a SIBLING, not an ANCESTOR, at that point.
/// Same reason GetX users wrap with GetBuilder — context matters.)
class _CounterView extends StatelessWidget {
  const _CounterView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter — simplest BLoC'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
            // SEND event: intention, not mutation.
            onPressed: () =>
                context.read<CounterBloc>().add(const CounterReset()),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            // ── BlocBuilder REBUILDS only this Text on state change ───────
            // GetX equivalent: Obx(() => Text("${controller.count}"))
            BlocBuilder<CounterBloc, CounterState>(
              builder: (context, state) {
                return Text(
                  '${state.count}',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
            const SizedBox(height: 24),
            // Teaching aid: shows current state object as string.
            // Watch it change with each event in DevTools / console.
            BlocBuilder<CounterBloc, CounterState>(
              buildWhen: (previous, current) => false, // never rebuilds
              builder: (context, state) => const Text(
                'Tip: open DevTools → Logging to see events/states',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'dec',
            tooltip: 'Decrement',
            onPressed: () =>
                context.read<CounterBloc>().add(const CounterDecremented()),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'inc',
            tooltip: 'Increment',
            onPressed: () =>
                context.read<CounterBloc>().add(const CounterIncremented()),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// ─── COMMON MISTAKES (GetX → BLoC migrants) ────────────────────────────────
// ❌ context.watch<CounterBloc>().add(...) inside onPressed
//    → watch REBUILDS the button on every state change. Use `read` for events.
// ❌ setState(() { ... }) alongside Bloc
//    → pick ONE source of truth. If Bloc owns `count`, delete local variable.
// ❌ Business logic inside builder: `if (state.count > 10) launchUrl(...)`
//    → builder must be PURE. Move side effects to BlocListener.
// ❌ BlocProvider(create: ...) inside build() of a widget that rebuilds often
//    → a NEW Bloc is created per rebuild, state resets. Lift Provider higher.
