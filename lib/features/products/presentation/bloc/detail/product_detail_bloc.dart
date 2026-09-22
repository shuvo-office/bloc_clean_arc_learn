// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTS > PRESENTATION > BLOC > DETAIL (event + state + bloc)
// ═══════════════════════════════════════════════════════════════════════════
// WHY A SECOND BLOC?
//   List and detail have INDEPENDENT lifecycles:
//     • List lives as long as the catalogue screen (filter, refresh...).
//     • Detail is created per navigation (/products/5), dies on back.
//   One mega-Bloc holding `products + selectedProduct` couples them:
//   popping detail would need manual cleanup. Separate Blocs = separate
//   BlocProviders = automatic dispose via go_router page lifecycle.
//
// HOW THE ID ARRIVES:
//   go_router parses '/products/5' → passes id: 5 to ProductDetailPage →
//   page creates DetailBloc via get_it, fires ProductDetailRequested(5).
//   Router NEVER fetches data — it only delivers the id. Bloc owns state.
//
// Also demonstrates the "pass initial data" optimization (commented in
// product_detail_page.dart): list can hand over its cached Product so
// detail shows INSTANTLY, then revalidates from network (stale-while-
// revalidate). Best of both: instant + fresh.
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/product.dart';
import '../../../domain/usecases/product_usecases.dart';

// ═══════════════════════ EVENTS ═══════════════════════

sealed class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Load product [id]. Optional [cached] shows instantly while refetching.
class ProductDetailRequested extends ProductDetailEvent {
  final int id;
  final Product? cached;

  const ProductDetailRequested(this.id, {this.cached});

  @override
  List<Object?> get props => [id, cached];
}

// ═══════════════════════ STATE ═══════════════════════

enum ProductDetailStatus { initial, loading, loaded, error }

class ProductDetailState extends Equatable {
  final ProductDetailStatus status;
  final Product? product;
  final String errorMessage;

  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.product,
    this.errorMessage = '',
  });

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    Product? product,
    String? errorMessage,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, product, errorMessage];
}

// ═══════════════════════ BLOC ═══════════════════════

class ProductDetailBloc
    extends Bloc<ProductDetailEvent, ProductDetailState> {
  final GetProductDetail getProductDetail;

  ProductDetailBloc({required this.getProductDetail})
      : super(const ProductDetailState()) {
    on<ProductDetailRequested>(_onRequested);
  }

  Future<void> _onRequested(
    ProductDetailRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    // Cached product? Show it as `loaded` IMMEDIATELY (no spinner)...
    if (event.cached != null) {
      emit(state.copyWith(
        status: ProductDetailStatus.loaded,
        product: event.cached,
      ));
    } else {
      emit(state.copyWith(status: ProductDetailStatus.loading));
    }

    // ...then ALWAYS revalidate from network (price may have changed).
    final result = await getProductDetail(
      GetProductDetailParams(event.id),
    );

    result.fold(
      // Keep cached product visible on failure (if any) + error message.
      (failure) => emit(state.copyWith(
        status: ProductDetailStatus.error,
        errorMessage: failure.message,
      )),
      (product) => emit(state.copyWith(
        status: ProductDetailStatus.loaded,
        product: product,
      )),
    );
  }
}
