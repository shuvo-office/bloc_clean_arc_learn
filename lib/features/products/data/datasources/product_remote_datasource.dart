// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTS > DATA > DATASOURCES > PRODUCT REMOTE DATASOURCE (Dio)
// ═══════════════════════════════════════════════════════════════════════════
// The ONLY class that imports dio in the whole app.
//
// CONTRACT WITH REPOSITORY:
//   • Returns MODELS on success.
//   • THROWS on failure (DioException, FormatException...).
//   • NEVER returns Failures, NEVER imports core/error/failures.dart.
//   RepositoryImpl catches → converts to Left(Failure).
//
// DIO RESPONSE SHAPE:
//   GET /products            → response.data is List
//   GET /products/5          → response.data is Map
//   GET /products/categories → response.data is List<String>
// Always CHECK the runtime type before casting — a backend change from
// List → {data: [...]} otherwise crashes with an unreadable CastError.
// (The explicit `is List` guards below turn that into FormatException,
// which becomes a friendly ServerFailure message.)
//
// TIMEOUTS / NO INTERNET:
//   Dio throws DioExceptionType.connectionTimeout / receiveTimeout /
//   connectionError. We do NOT map them here — RepositoryImpl owns the
//   DioException → Failure translation (single mapping table).
// ───────────────────────────────────────────────────────────────────────────
import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';
import '../models/product_model.dart';

/// Thrown when the server answers but the body isn't the shape we expect.
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException([this.message = 'Server error', this.statusCode]);
}

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel> getProductDetail(int id);
  Future<List<String>> getCategories();
  Future<List<ProductModel>> getProductsByCategory(String category);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio dio;

  // Dio injected via get_it (shared instance from core/network/dio_client).
  ProductRemoteDataSourceImpl(this.dio);

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await dio.get(ApiConstants.products);
    return _parseProductList(response);
  }

  @override
  Future<ProductModel> getProductDetail(int id) async {
    final response = await dio.get(ApiConstants.productDetail(id));
    // FakeStoreAPI returns {} with 200 for unknown ids → treat as 404.
    final data = response.data;
    if (data is Map<String, dynamic> && data.isEmpty ||
        response.statusCode == 404) {
      throw const ServerException('Product not found', 404);
    }
    if (data is! Map<String, dynamic>) {
      throw const ServerException('Unexpected product format');
    }
    return ProductModel.fromJson(data);
  }

  @override
  Future<List<String>> getCategories() async {
    final response = await dio.get(ApiConstants.categories);
    final data = response.data;
    if (data is! List) {
      throw const ServerException('Unexpected categories format');
    }
    return data.map((e) => e.toString()).toList();
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final response = await dio.get(
      ApiConstants.productsByCategory(category),
    );
    return _parseProductList(response);
  }

  // ── Shared list parser (both catalogue endpoints return a JSON array) ─────
  List<ProductModel> _parseProductList(Response response) {
    final data = response.data;
    if (data is! List) {
      throw const ServerException('Unexpected products format');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }
}
