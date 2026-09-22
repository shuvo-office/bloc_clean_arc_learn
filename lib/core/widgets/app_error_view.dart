// ═══════════════════════════════════════════════════════════════════════════
// CORE > WIDGETS > APP ERROR VIEW
// ═══════════════════════════════════════════════════════════════════════════
// Shared "something went wrong" widget used by EVERY feature (products,
// future auth, orders...). Keeps error UI CONSISTENT across the app.
//
// Props:
//   message : Failure.message from state (already user-friendly — the
//             Repository mapped DioException → "No internet..." etc.)
//   onRetry : sends the load Event again, e.g.
//             () => context.read<ProductsBloc>().add(const ProductsRequested())
//
// Usage inside BlocBuilder:
//   if (state.status == ProductsStatus.error && state.products.isEmpty) {
//     return AppErrorView(message: state.errorMessage, onRetry: ...);
//   }
// NOTE the `isEmpty` guard: if we HAVE cached data, show the stale list +
// Snackbar instead (see products_page.dart). Full-screen error only when
// there is NOTHING to show.
import 'package:flutter/material.dart';

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const AppErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.cloud_off_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
