// ═══════════════════════════════════════════════════════════════════════════
// PRODUCTS > DOMAIN > ENTITIES > PRODUCT
// ═══════════════════════════════════════════════════════════════════════════
// Real API entity. Compare with Todo entity (3 fields, local only):
//   • More fields (price, image, rating...) — shaped by REAL JSON.
//   • `rating` is a NESTED object in FakeStoreAPI → we flatten it into
//     two primitives (rating, ratingCount). DOMAIN decides the shape;
//     the Model handles the ugly nesting. UI never sees `json['rating']`.
//   • Business helpers live here: formattedPrice, hasDiscount...
//
// Raw FakeStoreAPI item for reference:
//   {
//     "id": 1, "title": "Fjallraven Backpack", "price": 109.95,
//     "description": "...", "category": "men's clothing",
//     "image": "https://fakestoreapi.com/img/....jpg",
//     "rating": { "rate": 3.9, "count": 120 }
//   }
import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final double rating; // 0.0 – 5.0
  final int ratingCount;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.ratingCount,
  });

  // ── Business helpers (DOMAIN logic, reused by list + detail + cart) ──────
  /// "$109.95" — one formatting rule for the whole app.
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  /// "3.9 (120)" — rating line shown under every product card.
  String get ratingLabel => '$rating ★ ($ratingCount)';

  /// Fake "sale" rule for teaching: electronics over $100 show a badge.
  /// Real app: `discountPercent` field from backend. Same idea.
  bool get isOnSale => category == 'electronics' && price > 100;

  @override
  List<Object> get props => [
        id,
        title,
        price,
        description,
        category,
        imageUrl,
        rating,
        ratingCount,
      ];
}
