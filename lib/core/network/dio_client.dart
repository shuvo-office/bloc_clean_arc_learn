// ═══════════════════════════════════════════════════════════════════════════
// CORE > NETWORK > DIO CLIENT
// ═══════════════════════════════════════════════════════════════════════════
// WHAT IS THIS?
//   A pre-configured Dio instance shared by ALL RemoteDataSources.
//   Registered as LazySingleton in injection_container.dart.
//
// WHAT'S CONFIGURED (and why):
//   1. baseUrl            → every request is relative (dio.get('/products')).
//   2. connectTimeout / receiveTimeout → requests FAIL FAST (15s) instead of
//      hanging forever on bad networks. Timeouts surface as DioExceptionType
//      .connectionTimeout → mapped to ServerFailure('check connection').
//   3. LogInterceptor     → prints REQUEST → RESPONSE → ERROR in console.
//      This is your GetX `Get.log` / http `print(res.body)` equivalent,
//      but automatic for every call. `requestBody: true` shows POST payloads.
//   4. Headers            → JSON by default. Add auth token here later:
//        options.headers['Authorization'] = 'Bearer $token'
//
// GETX COMPARISON:
//   GetConnect:  class Api extends GetConnect { httpClient.baseUrl = ...; }
//   Dio:         same idea, but interceptors are first-class (onRequest /
//                onResponse / onError hooks) — e.g. auto-refresh token on 401
//                then RETRY the original request. See commented example below.
//
// BLoC RULE: Dio lives ONLY in DATA layer. Bloc/UseCases never import dio.
// ───────────────────────────────────────────────────────────────────────────
import 'package:dio/dio.dart';

import 'api_constants.dart';

/// Builds the shared Dio instance. Called ONCE from injection_container.
Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.fakeStoreBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      // JSON in/out by default. FakeStoreAPI speaks JSON.
      contentType: 'application/json',
      responseType: ResponseType.json,
      // Accept any 2xx AND 404 (we map 404 → "not found" Failure ourselves).
      // Other 4xx/5xx throw DioExceptionType.badResponse → ServerFailure.
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300 ||
          status == 404,
    ),
  );

  // ── Logging: every request/response/error hits the console ────────────────
  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: false, // headers are noisy; turn on when debugging auth
      requestBody: true,
      responseHeader: false,
      responseBody: false, // FakeStore lists are HUGE; log body only when needed
      error: true,
      logPrint: (obj) {
        // ignore: avoid_print
        print('🌐 DIO › $obj');
      },
    ),
  );

  return dio;
}

// ─── AUTH / TOKEN REFRESH TEMPLATE (uncomment when your API needs login) ────
// class AuthInterceptor extends Interceptor {
//   final Future<String?> Function() getToken;
//   AuthInterceptor(this.getToken);
//
//   @override
//   void onRequest(
//     RequestOptions options,
//     RequestInterceptorHandler handler,
//   ) async {
//     final token = await getToken();
//     if (token != null) {
//       options.headers['Authorization'] = 'Bearer $token';
//     }
//     handler.next(options); // continue to server
//   }
//
//   @override
//   void onError(DioException err, ErrorInterceptorHandler handler) async {
//     // On 401: refresh token ONCE, then retry original request.
//     if (err.response?.statusCode == 401) {
//       // final newToken = await refreshToken();
//       // err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
//       // final retry = await Dio().fetch(err.requestOptions);
//       // return handler.resolve(retry);
//     }
//     handler.next(err); // not 401 → pass error down to DataSource
//   }
// }
// Usage: dio.interceptors.add(AuthInterceptor(() async => storage.read('token')));
