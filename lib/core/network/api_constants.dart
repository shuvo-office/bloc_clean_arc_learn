// ═══════════════════════════════════════════════════════════════════════════
// CORE > NETWORK > API CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════
// Central place for base URLs + endpoints.
//
// WHY NOT hardcode URLs in the DataSource?
//   • One place to switch dev/staging/prod (via --dart-define later).
//   • DataSource methods stay short: dio.get(ApiConstants.products).
//
// FakeStoreAPI (https://fakestoreapi.com) — free, no API key, made for
// learning: products with title/price/image/rating. Endpoints used here:
//   GET /products              → List<Product>
//   GET /products/{id}         → Product detail
//   GET /products/categories   → ["electronics","jewelery",...]
//   GET /products/category/{c} → filtered list
// Try them in a browser first — seeing raw JSON demystifies Models.
abstract class ApiConstants {
  static const fakeStoreBaseUrl = 'https://fakestoreapi.com';

  static const products = '/products';
  static String productDetail(int id) => '/products/$id';
  static const categories = '/products/categories';
  static String productsByCategory(String category) =>
      '/products/category/$category';
}
