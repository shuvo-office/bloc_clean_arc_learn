// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTS > PRESENTATION > BLOC > EVENT + STATE + BLOC (list screen)
// ═══════════════════════════════════════════════════════════════════════════
// This Bloc manages the CATALOGUE screen: product grid + category filter +
// pull-to-refresh. Detail screen has its OWN Bloc (bloc/detail/) because it
// has a different lifecycle (one product, loads by id from route param).
//
// EVENTS:
//   ProductsRequested          → initial load (categories + all products)
//   ProductsRefreshed          → pull-to-refresh (keep old list visible!)
//   ProductsCategorySelected   → filter chip tapped ("all" = unfiltered)
//
// REFRESH vs REQUEST (subtle, important):
//   Requested: list is EMPTY → emit loading → shimmer skeletons.
//   Refreshed: list is FULL  → do NOT emit loading (would flash skeletons).
//     Instead keep showing stale list under RefreshIndicator, then swap.
//     Failure → keep stale list + error Snackbar (never blank the screen).
//
// CATEGORIES are part of THIS state (chips live on the same screen).
// Alternative: separate CategoryBloc. Overkill here — one screen, one Bloc.
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/product_usecases.dart';
import '../../domain/entities/product.dart';

// ═══════════════════════ EVENTS ═══════════════════════

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load — fired once when ProductsPage appears.
class ProductsRequested extends ProductsEvent {
  const ProductsRequested();
}

/// Pull-to-refresh — re-fetch current filter, keep stale list visible.
class ProductsRefreshed extends ProductsEvent {
  const ProductsRefreshed();
}

/// Category chip tapped. 'all' (see state.allCategory) = no filter.
class ProductsCategorySelected extends ProductsEvent {
  final String category;
  const ProductsCategorySelected(this.category);

  @override
  List<Object?> get props => [category];
}

// ═══════════════════════ STATE ═══════════════════════

enum ProductsStatus { initial, loading, loaded, error }

class ProductsState extends Equatable {
  static const allCategory = 'all';

  final ProductsStatus status;
  final List<Product> products;
  final List<String> categories;
  final String selectedCategory;
  final String errorMessage;

  /// True while pull-to-refresh spinner should show (stale list visible).
  final bool isRefreshing;

  const ProductsState({
    this.status = ProductsStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.selectedCategory = allCategory,
    this.errorMessage = '',
    this.isRefreshing = false,
  });

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    List<String>? categories,
    String? selectedCategory,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return ProductsState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        products,
        categories,
        selectedCategory,
        errorMessage,
        isRefreshing,
      ];
}

// ═══════════════════════ BLOC ═══════════════════════

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final GetProducts getProducts;
  final GetCategories getCategories;
  final GetProductsByCategory getProductsByCategory;

  ProductsBloc({
    required this.getProducts,
    required this.getCategories,
    required this.getProductsByCategory,
  }) : super(const ProductsState()) {
    on<ProductsRequested>(_onRequested);
    on<ProductsRefreshed>(_onRefreshed);
    on<ProductsCategorySelected>(_onCategorySelected);
  }

  // ── Initial: shimmer (empty list) → categories + products in parallel ─────
  Future<void> _onRequested(
    ProductsRequested event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(status: ProductsStatus.loading));

    // Categories failing must NOT kill the product list — run separately,
    // keep whatever succeeds. (Real-world resilience: partial success.)
    final categoriesResult = await getCategories(NoParams());
    final productsResult = await getProducts(NoParams());

    final categories = categoriesResult.fold(
      (_) => <String>[],
      (list) => list,
    );

    productsResult.fold(
      (failure) => emit(state.copyWith(
        status: ProductsStatus.error,
        categories: categories,
        errorMessage: failure.message,
      )),
      (products) => emit(state.copyWith(
        status: ProductsStatus.loaded,
        products: products,
        categories: categories,
      )),
    );
  }

  // ── Refresh: NO loading state — stale list stays, spinner via isRefreshing ─
  Future<void> _onRefreshed(
    ProductsRefreshed event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));

    final result = state.selectedCategory == ProductsState.allCategory
        ? await getProducts(NoParams())
        : await getProductsByCategory(
            GetProductsByCategoryParams(state.selectedCategory),
          );

    result.fold(
      // Stale list preserved (we don't touch `products`) + error for Listener.
      (failure) => emit(state.copyWith(
        isRefreshing: false,
        status: ProductsStatus.error,
        errorMessage: failure.message,
      )),
      (products) => emit(state.copyWith(
        isRefreshing: false,
        status: ProductsStatus.loaded,
        products: products,
      )),
    );
  }

  // ── Filter: loading ONLY if we have nothing cached for this filter ────────
  // Simple version: always show loading spinner row state. The page decides
  // shimmer (empty) vs list+overlay (non-empty) from state.products.
  Future<void> _onCategorySelected(
    ProductsCategorySelected event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(
      selectedCategory: event.category,
      status: ProductsStatus.loading,
    ));

    final result = event.category == ProductsState.allCategory
        ? await getProducts(NoParams())
        : await getProductsByCategory(
            GetProductsByCategoryParams(event.category),
          );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProductsStatus.error,
        errorMessage: failure.message,
      )),
      (products) => emit(state.copyWith(
        status: ProductsStatus.loaded,
        products: products,
      )),
    );
  }
}
