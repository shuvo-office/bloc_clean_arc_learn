# AGENTS.md — `features/products` (remote API feature template)

> Scope: everything under `lib/features/products/`.
> Inherits root `AGENTS.md`; rules here win on conflict.

## What this feature demonstrates

Remote CRUD-shape flow: `FakeStoreAPI --Dio--> Model --Either--> Bloc --go_router--> list + detail`.
Copy this folder when adding any new HTTP-backed feature (orders, users, cart).

## Local rules

1. **Two Blocs, two lifecycles**: `presentation/bloc/products_bloc.dart` (catalogue: filter + refresh, lives on list page) and `presentation/bloc/detail/product_detail_bloc.dart` (one product, created per `/products/:id` navigation, dies on pop). Never merge into one mega-Bloc.
2. **Detail refetches by id always.** `extra` (cached `Product` from list tap) is paint-first hint only; deep links have `extra == null` and must still work.
3. **Category failure is non-fatal**: `_onRequested` keeps products even if `getCategories` fails (empty chips, list intact). Don't `Future.wait` them into all-or-nothing.
4. **Refresh never emits `loading`**: stale list stays visible; spinner via `isRefreshing` + `RefreshIndicator`. Only initial load (empty list) shows shimmer.
5. **Price parsing**: `(json['price'] as num).toDouble()` — FakeStoreAPI mixes int/double. Keep `_toInt` helper for `id`/`count`.
6. **Images**: always `CachedNetworkImage` with placeholder + errorWidget (offline/broken URLs are normal).
7. **New endpoint?** Add path to `core/network/api_constants.dart` → method on `ProductRemoteDataSource` (+ impl with `is List/Map` guard) → repo method with `DioException` mapping → usecase → event/handler. Then `flutter analyze`.
