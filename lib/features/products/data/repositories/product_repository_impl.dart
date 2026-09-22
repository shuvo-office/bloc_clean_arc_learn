// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTS > DATA > REPOSITORIES > PRODUCT REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════
// THE DioException → Failure TRANSLATION TABLE (memorize — every Dio app
// needs exactly this):
//
//   DioExceptionType.connectionTimeout │ receiveTimeout │ sendTimeout
//     → ServerFailure('Request timed out. Check your connection.')
//   DioExceptionType.connectionError (no internet, DNS, TLS)
//     → ServerFailure('No internet connection.')
//   404 status                        → ServerFailure('...not found')
//   401                               → ServerFailure('Session expired...')
//   5xx                               → ServerFailure('Server error (500)...')
//   badResponse (other 4xx)           → ServerFailure('Request failed (403)')
//   ServerException (our guard)       → ServerFailure(message)
//   anything else                     → UnexpectedFailure
//
// WHY HERE and not in the DataSource?
//   Single mapping table per feature → consistent messages everywhere,
//   and DataSources stay reusable (same DataSource could feed two repos
//   with different error wording — rare, but the seam exists).
//
// GETX COMPARISON:
//   GetConnect: `if (res.hasError) return Future.error(res.statusText!)`
//   scattered per call. Here: ONE _mapDioError used by all 4 methods.
// ───────────────────────────────────────────────────────────────────────────
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      return Right(await remoteDataSource.getProducts());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure('Failed to load products'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductDetail(int id) async {
    try {
      return Right(await remoteDataSource.getProductDetail(id));
    } on DioException catch (e) {
      return Left(_mapDioError(e, notFoundMessage: 'Product not found'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure('Failed to load product'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCategories() async {
    try {
      return Right(await remoteDataSource.getCategories());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure('Failed to load categories'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String category,
  ) async {
    try {
      return Right(await remoteDataSource.getProductsByCategory(category));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(UnexpectedFailure('Failed to load products'));
    }
  }

  // ── THE TABLE ─────────────────────────────────────────────────────────────
  ServerFailure _mapDioError(DioException e, {String? notFoundMessage}) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout: // dio ≥5.11: (de)serialization timeout
        return const ServerFailure(
          'Request timed out. Check your connection and retry.',
        );
      case DioExceptionType.connectionError:
        return const ServerFailure(
          'No internet connection. Check Wi-Fi / mobile data.',
        );
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 404) {
          return ServerFailure(notFoundMessage ?? 'Resource not found (404)');
        }
        if (code == 401) {
          return const ServerFailure('Session expired. Please log in again.');
        }
        if (code != null && code >= 500) {
          return ServerFailure('Server error ($code). Try again later.');
        }
        return ServerFailure('Request failed ($code). Try again.');
      case DioExceptionType.cancel:
        return const ServerFailure('Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const ServerFailure('Insecure connection blocked.');
      case DioExceptionType.unknown:
        return ServerFailure('Network error: ${e.message ?? 'unknown'}');
    }
  }
}
