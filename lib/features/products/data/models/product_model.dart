// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTS > DATA > MODELS > PRODUCT MODEL
// ═══════════════════════════════════════════════════════════════════════════
// Handles the REAL JSON quirks so DOMAIN stays clean:
//
//   1. `id` arrives as int, but some APIs send "id": "1" (String).
//      → `_toInt()` tolerates both. Delete when your backend is typed.
//   2. `price` arrives as int (22) OR double (109.95) — Dart's `as double`
//      CRASHES on int. → `(json['price'] as num).toDouble()` handles both.
//      ★ This is the #1 crash in beginner API apps. Memorize it.
//   3. `rating` is NESTED ({rate, count}) → flattened to primitives.
//   4. Missing keys → sensible defaults (?? fallbacks) instead of crash.
//
// RULE: Model NEVER throws on weird JSON if a default is reasonable.
// If shape is truly unusable → throw FormatException → Repo maps to
// ValidationFailure / ServerFailure. Never let raw JSON crash the Bloc.
import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.title,
    required super.price,
    required super.description,
    required super.category,
    required super.imageUrl,
    required super.rating,
    required super.ratingCount,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Nested rating block may be absent → default to empty map.
    final ratingJson =
        (json['rating'] as Map<String, dynamic>?) ?? const {};

    return ProductModel(
      id: _toInt(json['id']),
      title: (json['title'] ?? 'Untitled').toString(),
      // num covers int AND double from the API.
      price: (json['price'] as num? ?? 0).toDouble(),
      description: (json['description'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      imageUrl: (json['image'] ?? '').toString(),
      rating: (ratingJson['rate'] as num? ?? 0).toDouble(),
      ratingCount: _toInt(ratingJson['count']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'description': description,
        'category': category,
        'image': imageUrl,
        'rating': {'rate': rating, 'count': ratingCount},
      };

  /// Tolerates int, double, and numeric String ids.
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
