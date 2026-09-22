// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTS > DOMAIN > USECASES
// ═══════════════════════════════════════════════════════════════════════════
// 4 UseCases, one per user intention. Kept in one file for learning;
// split per-file when the team grows.
//
// NOTICE vs Todo UseCases: zero validation here (no user input — the API
// owns the data). UseCases are pure delegation + a seam for future rules
// (sorting, filtering out-of-stock, merging wishlist state...).
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

// ── 1. Catalogue ─────────────────────────────────────────────────────────────
class GetProducts extends UseCase<List<Product>, NoParams> {
  final ProductRepository repository;
  GetProducts(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) =>
      repository.getProducts();
}

// ── 2. Detail ────────────────────────────────────────────────────────────────
class GetProductDetailParams extends Equatable {
  final int id;
  const GetProductDetailParams(this.id);

  @override
  List<Object> get props => [id];
}

class GetProductDetail extends UseCase<Product, GetProductDetailParams> {
  final ProductRepository repository;
  GetProductDetail(this.repository);

  @override
  Future<Either<Failure, Product>> call(GetProductDetailParams params) =>
      repository.getProductDetail(params.id);
}

// ── 3. Categories (filter chips) ─────────────────────────────────────────────
class GetCategories extends UseCase<List<String>, NoParams> {
  final ProductRepository repository;
  GetCategories(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) =>
      repository.getCategories();
}

// ── 4. Filtered catalogue ────────────────────────────────────────────────────
class GetProductsByCategoryParams extends Equatable {
  final String category;
  const GetProductsByCategoryParams(this.category);

  @override
  List<Object> get props => [category];
}

class GetProductsByCategory
    extends UseCase<List<Product>, GetProductsByCategoryParams> {
  final ProductRepository repository;
  GetProductsByCategory(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(
    GetProductsByCategoryParams params,
  ) =>
      repository.getProductsByCategory(params.category);
}
