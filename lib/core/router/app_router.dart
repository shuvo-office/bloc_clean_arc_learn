// ═══════════════════════════════════════════════════════════════════════════
// CORE > ROUTER > APP ROUTER (go_router)
// ═══════════════════════════════════════════════════════════════════════════
// ROUTING FOR BLoC APPS — the short answer to "go_router or what?":
//
//   ✅ go_router — recommended. Declarative, URL-based, deep-linking works
//      on web/mobile (paste /products/5 → opens detail). Backed by Flutter
//      team. Works WITH BLoC (router holds NO business state).
//   ➖ auto_route — codegen alternative, similar power, extra build step.
//   ❌ GetX routing — couples navigation to GetX controller lifecycle;
//      mixing Get.to() with BlocProviders causes disposal surprises.
//
// GOLDEN RULES (BLoC + go_router):
//   1. Router creates PAGES, pages create BLOCS (BlocProvider in page file).
//      Never put BlocProvider inside the router — navigation rebuilds would
//      recreate Blocs and wipe state.
//   2. Pass PRIMITIVES via path params (id as int), full objects via `extra`
//      ONLY as a cache hint (detail refetches anyway — survives deep links
//      where `extra` is null).
//   3. context.go (replace stack) for tabs/bottom-nav; context.push (add on
//      top) for detail screens so back-button returns to the list.
//   4. Navigation (go/push/pop) is called from UI (onTap), NEVER from inside
//      a Bloc — Blocs emit STATE, UI/listener decides to navigate. (Bloc
//      importing BuildContext/router = untestable. Status → Listener → push.)
//
// ROUTES:
//   /               → HomePage (hub)
//   /counter        → CounterPage
//   /todos          → TodoPage
//   /products       → ProductsPage
//   /products/:id   → ProductDetailPage (id parsed here, cache via extra)
// ───────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/counter/presentation/pages/counter_page.dart';
import '../../features/products/domain/entities/product.dart';
import '../../features/products/presentation/pages/product_detail_page.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/todo/presentation/pages/todo_page.dart';
import '../../main.dart' show HomePage;

/// Central router. Created ONCE in main.dart, passed to MaterialApp.router.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true, // logs every go/push/pop — learning gold
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'counter',
            name: 'counter',
            builder: (context, state) => const CounterPage(),
          ),
          GoRoute(
            path: 'todos',
            name: 'todos',
            builder: (context, state) => const TodoPage(),
          ),
          GoRoute(
            path: 'products',
            name: 'products',
            builder: (context, state) => const ProductsPage(),
            routes: [
              GoRoute(
                // :productId is a PATH PARAM — /products/5 → {'productId':'5'}
                path: ':productId',
                name: 'product-detail',
                builder: (context, state) {
                  final raw =
                      state.pathParameters['productId'] ?? '0';
                  final id = int.tryParse(raw) ?? 0;
                  // `extra` carries the cached Product from the list tap.
                  // Direct URL open → extra is null → page loads by id.
                  final cached = state.extra is Product
                      ? state.extra as Product
                      : null;
                  return ProductDetailPage(
                    productId: id,
                    cachedProduct: cached,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
    // ── Friendly 404 instead of red screen on unknown URLs ──────────────────
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No route for ${state.uri}'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── NAVIGATION CHEAT SHEET (UI code) ───────────────────────────────────────
// context.go('/products')        // REPLACE stack (tabs, logout, home)
// context.push('/products/5')    // PUSH on top (detail → back returns)
// context.pop()                  // back (like Navigator.pop / Get.back())
// context.pushNamed('product-detail',
//   pathParameters: {'productId': '5'}, extra: product)
// // BlocListener navigation (auth redirect example):
// BlocListener<AuthBloc, AuthState>(
//   listenWhen: (p, c) => c.status == AuthStatus.unauthenticated,
//   listener: (context, _) => context.go('/login'),
//   child: ...,
// )
