// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTS > PRESENTATION > PAGES > PRODUCTS PAGE (catalogue)
// ═══════════════════════════════════════════════════════════════════════════
// The "real app" screen. Four UI branches from ONE BlocBuilder:
//
//   loading + empty  → AppLoadingList (shimmer skeletons)
//   error   + empty  → AppErrorView (full-screen + Retry)
//   loaded/error + items → RefreshIndicator + chips + list
//   loaded + empty   → "No products in this category"
//
// NAVIGATION (go_router):
//   push  = detail on top, back returns to list (state PRESERVED — the
//           ProductsBloc lives in THIS page's Provider, untouched).
//   extra = pass cached Product for instant detail paint (see detail page).
//
// BLOC SCOPE WARNING:
//   BlocProvider lives HERE (around _ProductsView), NOT in the router.
//   Router creates PAGES, Blocs belong to pages. If Provider moved into
//   app_router.dart, every navigation would REBUILD the Bloc → list refetch.
// ───────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_list.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/products_bloc.dart';
import '../widgets/product_card.dart';
import '../../domain/entities/product.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ProductsBloc>()..add(const ProductsRequested()),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatelessWidget {
  const _ProductsView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductsBloc, ProductsState>(
      // Snackbar only when we HAVE stale data (empty case uses AppErrorView).
      listenWhen: (prev, curr) =>
          curr.status == ProductsStatus.error && curr.products.isNotEmpty,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.errorMessage)));
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Shop — FakeStore API + Dio')),
        body: BlocBuilder<ProductsBloc, ProductsState>(
          builder: (context, state) {
            // ── 1. First load → shimmer ─────────────────────────────────────
            if (state.status == ProductsStatus.loading &&
                state.products.isEmpty) {
              return const AppLoadingList();
            }
            // ── 2. First load failed → full-screen error ────────────────────
            if (state.status == ProductsStatus.error &&
                state.products.isEmpty) {
              return AppErrorView(
                message: state.errorMessage,
                onRetry: () => context
                    .read<ProductsBloc>()
                    .add(const ProductsRequested()),
              );
            }
            // ── 3. Data (fresh or stale) → chips + pull-to-refresh list ─────
            return Column(
              children: [
                _CategoryChips(state: state),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      // Await the NEXT non-refreshing state so the spinner
                      // hides exactly when new data (or error) arrives.
                      final bloc = context.read<ProductsBloc>();
                      bloc.add(const ProductsRefreshed());
                      await bloc.stream.firstWhere(
                        (s) => !s.isRefreshing,
                      );
                    },
                    child: state.products.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text('No products in this category.'),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: state.products.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final Product product = state.products[index];
                              return ProductCard(
                                product: product,
                                onTap: () => context.push(
                                  '/products/${product.id}',
                                  extra: product, // cached → instant detail
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Horizontal filter chips. 'All' + API categories. Selected chip highlighted.
class _CategoryChips extends StatelessWidget {
  final ProductsState state;

  const _CategoryChips({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.categories.isEmpty) return const SizedBox.shrink();
    final chips = [ProductsState.allCategory, ...state.categories];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = chips[index];
          final selected = category == state.selectedCategory;
          return FilterChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => context
                .read<ProductsBloc>()
                .add(ProductsCategorySelected(category)),
          );
        },
      ),
    );
  }
}
