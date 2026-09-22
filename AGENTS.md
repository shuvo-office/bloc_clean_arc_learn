# AGENTS.md — AI Agent Playbook (self-maintained)

> This file is the source of truth for AI coding agents working in this repo.
> Keep it updated whenever architecture, commands, or conventions change.
> Feature folders may add their own `AGENTS.md` with local rules —
> those override this file within their scope.

## Stack (latest, Sep 2026)

`flutter_bloc 9` · `equatable 3` · `dartz` (Either) · `get_it 9` ·
`dio 5` · `go_router 18` · `cached_network_image 4` · `shimmer 4`

## Commands

```bash
flutter pub get              # install deps
flutter analyze              # must be 0 errors before finishing a task
flutter test                 # pure-Dart + widget tests
flutter run                  # FakeStoreAPI needs internet; Todo/Counter work offline
flutter pub outdated         # check for newer packages
flutter pub upgrade --major-versions   # bump (then re-run analyze + test)
```

## Architecture — non-negotiable rules

```
lib/
  main.dart                  # MaterialApp.router + AppBlocObserver + HomePage
  injection_container.dart   # get_it graph (Dio → DataSource → Repo → UseCase → Bloc)
  core/                      # shared: error/ usecases/ network/ router/ widgets/
  features/<name>/
    domain/entities/         # pure Dart, Equatable, business helpers only
    domain/repositories/     # ABSTRACT contracts returning Either<Failure, T>
    domain/usecases/         # ONE business rule per class, params via *Params
    data/models/             # extends Entity + fromJson/toJson (JSON quirks HERE)
    data/datasources/        # ONLY place that touches I/O (Dio, storage); THROWS
    data/repositories/       # catches Exceptions → Left(Failure); NEVER throws up
    presentation/bloc/       # event/state/bloc; fold() maps Either → emit()
    presentation/pages/      # BlocProvider creates Bloc + fires initial event
    presentation/widgets/    # dumb widgets (data in, callbacks out)
```

1. **Dependencies point inward**: `data → domain ← presentation`. Domain imports NOTHING from data/presentation/Flutter.
2. **Errors**: DataSource throws (`DioException`, `ServerException`, `CacheException`) → RepositoryImpl maps to `Failure` (`ServerFailure`, `CacheFailure`, `ValidationFailure`, `UnexpectedFailure`) → Bloc `fold`s into state → UI renders. Never `try/catch` in Bloc UI code; never let raw Exceptions reach presentation.
3. **States immutable + Equatable**: never mutate `state.todos`; always `emit(state.copyWith(...))`.
4. **UI binding**: `context.read<B>().add(Event)` to send (never `watch` for events); `BlocBuilder` pure render; `BlocListener` side effects (snackbar/navigation).
5. **Blocs never navigate directly** — emit state, let `BlocListener` call `context.go/push`.
6. **Router creates PAGES, pages create BLOCS.** Never put `BlocProvider` in `app_router.dart`. Pass primitives via path params; full objects via `extra` only as cache hints (detail must refetch — deep links have no `extra`).
7. **Dio quirks**: `(json['price'] as num).toDouble()` (API sends int OR double); guard `response.data is List/Map` before casting; all Dio config lives in `core/network/dio_client.dart`.
8. **DI**: `registerFactory` for Blocs/UseCases (fresh per screen), `registerLazySingleton` for Dio/DataSources/Repositories. Register leaf-first. Update the graph comment at the top of `injection_container.dart` when adding nodes.

## When adding a new feature

1. Copy the shape of `features/products/` (remote) or `features/todo/` (local).
2. Files in order: entity → repository contract → usecases → model → datasource → repo impl → bloc trio → widgets → pages.
3. Wire DI in `injection_container.dart` + route in `core/router/app_router.dart` (nested under `/` with `name:` set).
4. Handle all 4 UI branches: loading-empty (shimmer/spinner), error-empty (`AppErrorView` + retry), data (list), error-with-data (stale list + snackbar).
5. Heavily comment new files in this repo's teaching style (what/why + GetX comparison where helpful).
6. Finish with `flutter analyze` (0 errors) and update this file + `BLOC_CLEAN_GUIDE.md` if conventions changed.

## Don't

- No business logic in widgets/build methods; no `setState` for Bloc-owned data.
- No `BuildContext`, controllers, or widgets inside Events.
- No new HTTP client per datasource — reuse `sl<Dio>()`.
- No hardcoded URLs outside `core/network/api_constants.dart`.
- No `// TODO` leftovers — implement or file an issue in the guide.
