// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTS > PRESENTATION > PAGES > PRODUCT DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════════
// Route: /products/:id  (e.g. /products/5, deep-linkable from browser URL)
//
// TWO ways this page receives data:
//   1. `id` (REQUIRED, from go_router path param) → always refetch.
//   2. `cachedProduct` (OPTIONAL, from list's `extra`) → paint instantly,
//      then revalidate. Direct URL open / refresh → cached is null →
//      normal loading spinner.
//
// This is the stale-while-revalidate pattern: instant UX + fresh data.
// GetX equivalent: Get.arguments (untyped dynamic) — here `extra` is cast
// once in the ROUTER (app_router.dart), page receives a typed Product?.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/detail/product_detail_bloc.dart';
import '../../domain/entities/product.dart';

class ProductDetailPage extends StatelessWidget {
  final int productId;
  final Product? cachedProduct;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.cachedProduct,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ProductDetailBloc>()
        ..add(ProductDetailRequested(productId, cached: cachedProduct)),
      child: _ProductDetailView(productId: productId),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  final int productId;

  const _ProductDetailView({required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product #$productId')),
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          // ── Loading WITHOUT cache → centered spinner ──────────────────────
          if (state.status == ProductDetailStatus.loading &&
              state.product == null) {
            return const Center(child: CircularProgressIndicator());
          }
          // ── Error WITHOUT cache → full-screen retry ───────────────────────
          if (state.status == ProductDetailStatus.error &&
              state.product == null) {
            return AppErrorView(
              message: state.errorMessage,
              onRetry: () => context
                  .read<ProductDetailBloc>()
                  .add(ProductDetailRequested(productId)),
            );
          }
          // ── Product (fresh, or cached while revalidating) ─────────────────
          final product = state.product!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    height: 260,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => Container(
                      height: 260,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      size: 120,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (product.isOnSale)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SALE — electronics over \$100',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      product.formattedPrice,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(product.ratingLabel),
                  ],
                ),
                const SizedBox(height: 8),
                Chip(label: Text(product.category)),
                const SizedBox(height: 12),
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
