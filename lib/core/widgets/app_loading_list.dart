// ═══════════════════════════════════════════════════════════════════════════
// CORE > WIDGETS > APP LOADING LIST (shimmer skeletons)
// ═══════════════════════════════════════════════════════════════════════════
// Skeleton placeholders shown while the FIRST load is in flight.
// Better UX than a bare CircularProgressIndicator for lists: user sees the
// layout shape (image box + 2 text lines) and perceives faster loading.
//
// WHEN to show shimmer vs spinner vs stale list:
//   • status == loading && items.isEmpty → shimmer (nothing to show yet)
//   • pull-to-refresh (items NOT empty)  → RefreshIndicator spinner on top
//   • status == error   && items.isEmpty → AppErrorView (full-screen)
//   • status == error   && items NOT empty → stale list + Snackbar
// See products_page.dart for all four branches in one BlocBuilder.
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppLoadingList extends StatelessWidget {
  /// How many skeleton rows to paint.
  final int itemCount;

  const AppLoadingList({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 150,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 80, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
