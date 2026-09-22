// ═══════════════════════════════════════════════════════════════════════════
// MAIN — app entry point
// ═══════════════════════════════════════════════════════════════════════════
// STARTUP SEQUENCE:
//   1. WidgetsFlutterBinding.ensureInitialized() — required before ANY async
//      work (path_provider, Firebase, Hive...). Harmless if unused.
//   2. await di.init() — build the get_it dependency graph.
//   3. Bloc.observer = AppBlocObserver() — global event/transition logging.
//   4. runApp(MyApp()) — launch UI with go_router (MaterialApp.router).
//
// ROUTING: go_router (see lib/core/router/app_router.dart).
//   MaterialApp(home:) → MaterialApp.router(routerConfig:) changes:
//     • Navigator.push → context.push / context.go
//     • No BuildContext-less navigation: router needs context. From a Bloc,
//       emit state → BlocListener navigates (Blocs never import go_router).
// ───────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'injection_container.dart' as di;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Build dependency graph BEFORE UI needs it.
  await di.init();

  // Global Bloc logging — prints EVERY event + transition + error.
  // Like GetX GetObserver, but automatic for all Blocs. Keep ON while
  // learning; gate behind kDebugMode in production apps.
  Bloc.observer = AppBlocObserver();

  runApp(const MyApp());
}

/// Prints Event → Transition → State for ALL Blocs. Learning gold.
/// Example console line after tapping "+" on Counter:
///   🟡 EVENT [CounterBloc] CounterIncremented
///   🔵 CHANGE [CounterBloc] 4 → 5
class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    debugPrint('🟡 EVENT [${bloc.runtimeType}] $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('🔵 CHANGE [${bloc.runtimeType}] $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    debugPrint('🔴 ERROR [${bloc.runtimeType}] $error');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Created once per MyApp build — GoRouter caches internally, cheap.
    final router = createRouter();
    return MaterialApp.router(
      title: 'BLoC + Clean Arch Learn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

/// Hub screen — pick which feature to explore.
/// Counter = "BLoC in 3 files". Todo = "Clean Arch, local".
/// Products = "Clean Arch, real API (Dio) + go_router deep links".
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BLoC + Clean Arch — Learn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'You know GetX + MVC. This project teaches the BLoC + Clean '
            'Architecture equivalent — same apps, different philosophy.\n',
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.exposure_plus_1, size: 36),
              title: const Text('1. Counter — simplest BLoC'),
              subtitle: const Text(
                'Event → Bloc → State in 3 files.\n'
                'Start HERE. No UseCases, no repository.',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward),
              // go_router push: detail-style navigation, back returns here.
              onTap: () => context.push('/counter'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.checklist, size: 36),
              title: const Text('2. Todos — Clean Architecture, local'),
              subtitle: const Text(
                'Entity → Repository → UseCase → Bloc → UI.\n'
                'Either<Failure, Data> error handling + get_it DI.',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.push('/todos'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront, size: 36),
              title: const Text('3. Shop — real API (Dio + go_router)'),
              subtitle: const Text(
                'FakeStoreAPI products: list, filter chips, detail /products/:id.\n'
                'Shimmer loading, cached images, typed Dio errors.',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.push('/products'),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '📖 Open BLOC_CLEAN_GUIDE.md in the project root for the '
                'full GetX → BLoC translation course.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
