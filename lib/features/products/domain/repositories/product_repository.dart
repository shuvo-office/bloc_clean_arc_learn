// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTS > DOMAIN > REPOSITORIES > PRODUCT REPOSITORY (contract)
// ═══════════════════════════════════════════════════════════════════════════
// 4 operations the shop needs. Detail page uses getProductDetail (fresh fetch
// by id — deep-linkable via go_router /products/:id). Category filter uses
// getProductsByCategory. All return Either so EVERY network failure becomes
// a typed Failure the Bloc can render (no try/catch in UI).
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  /// GET /products — full catalogue.
  Future<Either<Failure, List<Product>>> getProducts();

  /// GET /products/{id} — single product (detail screen + deep links).
  Future<Either<Failure, Product>> getProductDetail(int id);

  /// GET /products/categories — ["electronics","jewelery",...].
  Future<Either<Failure, List<String>>> getCategories();

  /// GET /products/category/{name} — filtered catalogue.
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String category,
  );
}
