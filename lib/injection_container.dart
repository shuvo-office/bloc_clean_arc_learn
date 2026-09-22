// ═══════════════════════════════════════════════════════════════════════════
// INJECTION CONTAINER (Dependency Injection with get_it)
// ═══════════════════════════════════════════════════════════════════════════
// WHAT IS THIS?
// ────────────
// ONE place that knows HOW to build every object + its dependencies.
// Widgets ask for the finished product: `sl<TodoBloc>()`.
//
// GETX TRANSLATION (you know this well):
//   GetX:  Get.put(TodoController())  →  Get.find<TodoController>()
//   get_it: init() registers factories →  sl<TodoBloc>()
//
// REGISTRATION KINDS:
//   registerLazySingleton<T>(() => X())
//     → ONE shared instance, created on FIRST use. (like Get.put permanent)
//     → Use for: Dio, DataSources, Repositories (stateless / expensive).
//   registerFactory<T>(() => X())
//     → NEW instance on EVERY sl<T>() call. (like Get.create / default)
//     → Use for: Blocs, UseCases (stateful, must not leak between pages).
//
// ORDER MATTERS: leaf dependencies FIRST (Dio → DataSource → Repo →
// UseCase → Bloc), because each factory closure CAPTURES the previous one.
//
// CALL init() ONCE in main() before runApp().
//
// GRAPH (this app):
//   Dio (singleton)
//    └─ TodoLocalDataSource ─┐
//    └─ ProductRemoteDataSource ─┐
//         ├─ TodoRepository ─┬─ GetTodos/AddTodo/ToggleTodo/DeleteTodo ─┬─ TodoBloc
//         └─ ProductRepository ─┬─ GetProducts/GetProductDetail/ ─────────┬─ ProductsBloc
//                               └─ GetCategories/GetProductsByCategory ───┘ └─ ProductDetailBloc
// ───────────────────────────────────────────────────────────────────────────
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'core/network/dio_client.dart';
import 'features/products/data/datasources/product_remote_datasource.dart';
import 'features/products/data/repositories/product_repository_impl.dart';
import 'features/products/domain/repositories/product_repository.dart';
import 'features/products/domain/usecases/product_usecases.dart';
import 'features/products/presentation/bloc/detail/product_detail_bloc.dart';
import 'features/products/presentation/bloc/products_bloc.dart';
import 'features/todo/data/datasources/todo_local_datasource.dart';
import 'features/todo/data/repositories/todo_repository_impl.dart';
import 'features/todo/domain/repositories/todo_repository.dart';
import 'features/todo/domain/usecases/todo_usecases.dart';
import 'features/todo/presentation/bloc/todo_bloc.dart';

/// Global service locator. `sl` = short, typed alias for GetIt.instance.
/// Usage: `sl<TodoBloc>()`, `sl<GetProducts>()`, `sl<Dio>()`.
final sl = GetIt.instance;

Future<void> init() async {
  // ══════════════ CORE: network ══════════════
  // ONE Dio for the whole app (connection pool, interceptors shared).
  sl.registerLazySingleton<Dio>(createDio);

  // ══════════════ TODO (local, in-memory) ══════════════
  // Factory: each TodoPage gets a FRESH Bloc (old state must not leak).
  sl.registerFactory(
    () => TodoBloc(
      getTodos: sl(),
      addTodo: sl(),
      toggleTodo: sl(),
      deleteTodo: sl(),
    ),
  );

  // Factory: cheap, stateless wrappers — fresh copy is safest default.
  sl.registerFactory(() => GetTodos(sl()));
  sl.registerFactory(() => AddTodo(sl()));
  sl.registerFactory(() => ToggleTodo(sl()));
  sl.registerFactory(() => DeleteTodo(sl()));

  // LazySingleton: ONE repo shared by all 4 UseCases (single source of truth).
  // NOTE the interface→impl mapping: domain asks for TodoRepository,
  // get_it hands TodoRepositoryImpl. Swap impl here, domain never knows.
  sl.registerLazySingleton<TodoRepository>(
    () => TodoRepositoryImpl(sl()),
  );

  // LazySingleton: ONE in-memory store for the whole app session.
  sl.registerLazySingleton<TodoLocalDataSource>(
    () => TodoLocalDataSourceImpl(),
  );

  // ══════════════ PRODUCTS (remote, FakeStoreAPI via Dio) ══════════════
  // Factory: fresh Bloc per ProductsPage / ProductDetailPage.
  sl.registerFactory(
    () => ProductsBloc(
      getProducts: sl(),
      getCategories: sl(),
      getProductsByCategory: sl(),
    ),
  );
  sl.registerFactory(
    () => ProductDetailBloc(getProductDetail: sl()),
  );

  sl.registerFactory(() => GetProducts(sl()));
  sl.registerFactory(() => GetProductDetail(sl()));
  sl.registerFactory(() => GetCategories(sl()));
  sl.registerFactory(() => GetProductsByCategory(sl()));

  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );

  // DataSource receives the SHARED Dio singleton (sl<Dio>()).
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(sl()),
  );
}
