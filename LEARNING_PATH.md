# LEARNING_PATH.md — Where To Start (self-maintained)

> Numbered learning order for this repo. Read top-to-bottom, don't skip steps:
> if a step confuses you, the prerequisite is one of the earlier steps.
> KEEP THIS FILE UPDATED: when files move, routes change, or features are
> added/removed, update the paths and steps below in the same commit.

## Phase 1 — Setup + BLoC basics (Day 1)  

1. `pubspec.yaml` — skim the package comments (why each package exists).
2. `lib/main.dart` — startup sequence: `di.init()` → `AppBlocObserver` → `MaterialApp.router`.
3. Run the app (`flutter run`), open screen **1. Counter**, tap +/−, watch console logs.
4. `lib/features/counter/presentation/bloc/counter_event.dart` — what an Event is.
5. `lib/features/counter/presentation/bloc/counter_state.dart` — what a State is.
6. `lib/features/counter/presentation/bloc/counter_bloc.dart` — `on<Event>` → `emit(State)`. The whole pattern in ~60 lines.
7. `lib/features/counter/presentation/pages/counter_page.dart` — `read`/`add`, `BlocBuilder`.
8. `BLOC_CLEAN_GUIDE.md` §1 + §2 — mindset shift (GetX → BLoC) + the 4 building blocks.



## Phase 2 — Clean Architecture, local (Day 2)

1. `lib/core/error/failures.dart` + `lib/core/usecases/usecase.dart` — Failure + UseCase base.
2. `lib/features/todo/domain/entities/todo.dart` → `domain/repositories/todo_repository.dart` → `domain/usecases/todo_usecases.dart`.
3. `lib/features/todo/data/models/todo_model.dart` → `data/datasources/todo_local_datasource.dart` → `data/repositories/todo_repository_impl.dart`.
4. `lib/features/todo/presentation/bloc/todo_event.dart` → `todo_state.dart` → `todo_bloc.dart` (the `fold` pattern).
5. `lib/features/todo/presentation/pages/todo_page.dart` + `presentation/widgets/` — Listener (side effects) vs Builder (render).
6. `lib/injection_container.dart` — Todo half of the get_it graph.
7. `BLOC_CLEAN_GUIDE.md` §3 + §4 + §5 — rings, Either errors, DI.
8. **Exercise:** submit an empty-title todo → trace `ValidationFailure` from usecase to Snackbar.



## Phase 3 — Real API + routing (Day 3)

1. `lib/core/network/api_constants.dart` → `lib/core/network/dio_client.dart` → open `https://fakestoreapi.com/products` in a browser (see the raw JSON first).
2. `lib/features/products/data/models/product_model.dart` — the `(price as num).toDouble()` int/double fix.
3. `lib/features/products/data/datasources/product_remote_datasource.dart` → `data/repositories/product_repository_impl.dart` — DioException → Failure table.
4. `lib/features/products/presentation/bloc/products_bloc.dart` — refresh-without-loading, partial-success categories.
5. `lib/features/products/presentation/bloc/detail/product_detail_bloc.dart` — why a second Bloc (independent lifecycle).
6. `lib/features/products/presentation/pages/products_page.dart` → `product_detail_page.dart` — 4 UI branches, `extra` as cache hint.
7. `lib/core/router/app_router.dart` — go_router rules; try deep-linking `/products/5` in a new browser tab.
8. `BLOC_CLEAN_GUIDE.md` §11 + §12 + §8 translation table.



## Phase 4 — Prove it (Day 4)

1. `test/counter_bloc_test.dart` → `test/widget_test.dart` → run `flutter test`.
2. `BLOC_CLEAN_GUIDE.md` §9, Exercise 5 (`ClearCompleted`), then Exercise 6 (cart Cubit).
3. `AGENTS.md` — read before adding your own feature; copy `lib/features/products/` (remote) or `lib/features/todo/` (local) as template.



## Maintenance checklist (for file moves / new features)

- [ ] New feature added → insert its steps in the correct phase above.
- [ ] File renamed/moved → update the path in its step.
- [ ] Route added/changed → update step 23.
- [ ] New guide section → point to it from the matching phase.