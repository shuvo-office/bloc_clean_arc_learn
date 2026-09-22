# BLoC + Clean Architecture — Complete Learning Guide
### Written for a GetX + MVC developer

> How to use this repo: run the app, open screen **1. Counter**, then **2. Todos**.
> Every source file is heavily commented. This `.md` is the theory. The code is the practice.
> Read them together — file paths are given for every concept.

---

## 0. TL;DR — The One-Paragraph Version

**GetX + MVC:** one `Controller` holds mutable observables (`.obs`), talks to API directly, and the UI watches variables with `Obx`. Fast to write, but business logic, API code, and UI state live in one place.

**BLoC + Clean Arch:** UI sends immutable **Events** (“what happened”), a **Bloc** runs business rules (via **UseCases** → **Repository** → **DataSource**) and emits immutable **States** (“what to show”). UI only renders states. Layers depend inward, errors are typed (`Either<Failure, Data>`), dependencies are injected (`get_it`).

```
GetX:   UI --calls method--> Controller --mutates--> .obs --rebuilds--> Obx
BLoC:   UI --add(Event)--> Bloc --emit(State)--> Builder rebuilds
                           ↑ uses UseCase → Repository → DataSource
```

---

## 1. Mindset Shift: Mutable Variables → Event/State Stream

### GetX (what you know)

```dart
// controller
class CounterController extends GetxController {
  var count = 0.obs;              // MUTABLE observable
  void increment() => count.value++;  // mutate in place
}
// ui
Obx(() => Text('${controller.count}'));  // watches the VARIABLE
FloatingActionButton(onPressed: controller.increment);
```

Mental model: **shared variable**. Anyone can read/write it. UI re-runs when it changes.

### BLoC (what you're learning)

```dart
// event — lib/features/counter/presentation/bloc/counter_event.dart
class CounterIncremented extends CounterEvent { const CounterIncremented(); }
// state — lib/features/counter/presentation/bloc/counter_state.dart
class CounterState extends Equatable { final int count; ... }
// bloc — lib/features/counter/presentation/bloc/counter_bloc.dart
on<CounterIncremented>((event, emit) {
  emit(state.copyWith(count: state.count + 1));  // NEW object, old one untouched
});
// ui — lib/features/counter/presentation/pages/counter_page.dart
BlocBuilder<CounterBloc, CounterState>(builder: (context, state) => Text('${state.count}'));
FloatingActionButton(onPressed: () => context.read<CounterBloc>().add(const CounterIncremented()));
```

Mental model: **stream of snapshots**. UI never touches data — it mails an intent (`add`), receives a snapshot (`state`), renders it, discards it.

### Why immutable?

| GetX mutable | BLoC immutable |
|---|---|
| `count.value++` modifies the live object | `emit(CounterState(5))` creates a new object |
| History is lost (was it 3 or 4 before?) | Every state is loggable, replayable, testable |
| Two widgets mutating = race conditions | Events queue up, handlers run sequentially |
| `Obx` rebuilds on *any* `.obs` write | `BlocBuilder` rebuilds only when `props` differ (Equatable) |

**Exercise 1:** open `counter_bloc.dart`, uncomment `onChange`, press +/−, watch console. That log IS the reason companies choose BLoC — debugging = reading history.

---

## 2. The 4 BLoC Building Blocks (memorize)

| # | Piece | Question it answers | File in this repo |
|---|---|---|---|
| 1 | **Event** | “What just happened?” | `counter/.../counter_event.dart`, `todo/.../todo_event.dart` |
| 2 | **State** | “What should the screen show now?” | `counter_state.dart`, `todo_state.dart` |
| 3 | **Bloc** | “Given event + current state, what's the next state?” | `counter_bloc.dart`, `todo_bloc.dart` |
| 4 | **UI binding** | `read/add` to send, `Builder` to render, `Listener` for side effects | `counter_page.dart`, `todo_page.dart` |

### UI binding cheat sheet

```dart
// SEND (inside onPressed, onTap, initState) — use `read` (no rebuild)
context.read<CounterBloc>().add(const CounterIncremented());

// RENDER (pure: state -> widgets, NO Snackbar/navigation here)
BlocBuilder<CounterBloc, CounterState>(
  builder: (context, state) => Text('${state.count}'),
);

// SIDE EFFECTS (Snackbar, navigation, dialog — returns NO widget)
BlocListener<TodoBloc, TodoState>(
  listenWhen: (p, c) => c.status == TodoStatus.error,
  listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(...),
  child: ...,
);

// BOTH at once
BlocConsumer<TodoBloc, TodoState>(listener: ..., builder: ...);
```

### Golden rules (GetX migrants break these most)

1. **`read` to send, `watch`/`Builder` to render.** Never `context.watch<Bloc>().add(...)` inside `onPressed` — it rebuilds the button pointlessly.
2. **`builder` is pure.** No navigation, no Snackbar, no `add()` inside `builder` (infinite loop risk). Side effects → `Listener`.
3. **States are immutable.** Never `state.todos.add(x)`. Always `emit(state.copyWith(todos: [...state.todos, x]))`.
4. **One `BlocProvider` per screen, lifted high.** `create:` inside a fast-rebuilding widget = new Bloc per rebuild = state resets.

**Exercise 2:** in `counter_page.dart`, change one `read` to `watch`. Hot reload, press buttons — works, but notice (DevTools → rebuild counts) the button itself rebuilds. Change it back.

---

## 3. Clean Architecture: The 3 Rings

```
┌──────────────────────────────────────────────┐
│ PRESENTATION  UI + Bloc                      │  Flutter-dependent
│  todo_page.dart, todo_bloc.dart, widgets/    │  depends on DOMAIN
├──────────────────────────────────────────────┤
│ DOMAIN        Entity, Repository IF, UseCase  │  PURE DART (no Flutter!)
│  todo.dart, todo_repository.dart,            │  depends on NOTHING
│  todo_usecases.dart                          │
├──────────────────────────────────────────────┤
│ DATA          Model, DataSource, Repo IMPL    │  Flutter + plugins + http
│  todo_model.dart, todo_local_datasource.dart │  depends on DOMAIN
│  todo_repository_impl.dart                   │
└──────────────────────────────────────────────┘
         Dependency arrows point INWARD (Data -> Domain, UI -> Domain).
         Domain never imports Data or UI. Ever.
```

### File-by-file map (Todo feature — trace a load from UI down and back up)

| Order | File | Job | GetX equivalent |
|---|---|---|---|
| 1 | `presentation/pages/todo_page.dart` | Renders + sends events | `TodoView` + `Obx` |
| 2 | `presentation/bloc/todo_{event,state,bloc}.dart` | Event→state, calls UseCases | `TodoController` methods + `.obs` vars |
| 3 | `domain/usecases/todo_usecases.dart` | ONE business rule each (`GetTodos`, `AddTodo`…) | A single controller method |
| 4 | `domain/repositories/todo_repository.dart` | Abstract contract (`Either<Failure, …>`) | `abstract ApiService` (if you had one) |
| 5 | `domain/entities/todo.dart` | Pure business object | `Todo` model (minus JSON) |
| 6 | `data/repositories/todo_repository_impl.dart` | Catches Exceptions → `Left(Failure)` | `try/catch` inside controller |
| 7 | `data/datasources/todo_local_datasource.dart` | Touches storage (here: in-memory Map) | `DbHelper` / `ApiService` |
| 8 | `data/models/todo_model.dart` | `extends Todo` + `fromJson/toJson` | `Todo.fromJson` |
| 9 | `core/error/failures.dart` | Typed errors (`CacheFailure`…) | Raw `catch (e)` string |
| 10 | `core/usecases/usecase.dart` | `UseCase<Type, Params>` + `NoParams` | (no equivalent — new concept) |
| 11 | `injection_container.dart` | `get_it` wiring (replaces `Get.put`) | `Get.put` / Bindings |

**Trace `TodoRequested` end-to-end (do this in code now):**

1. `TodoPage` → `sl<TodoBloc>()..add(TodoRequested())`
2. `TodoBloc._onRequested` → `emit(loading)` → `await getTodos(NoParams())`
3. `GetTodos.call` → `repository.getTodos()`
4. `TodoRepositoryImpl.getTodos` → `localDataSource.getTodos()` → `Right(models)`
5. Back up: `fold(Left→error state, Right→loaded state)` → `emit(loaded, todos)`
6. `BlocBuilder` rebuilds list. Done. 6 hops, each testable alone.

### Entity vs Model (the #1 confusion)

```dart
// ENTITY — domain/entities/todo.dart — business meaning only
class Todo extends Equatable { final String id, title; final bool isDone; ... }

// MODEL — data/models/todo_model.dart — entity + serialization
class TodoModel extends Todo {
  factory TodoModel.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => ...;
}
```

API renames `title` → `task_name`? Edit `TodoModel.fromJson` only. Bloc, UseCases, UI untouched. In MVC that rename breaks controller + UI.

**Exercise 3:** rename the JSON key `isDone` → `is_completed` in `TodoModel.fromJson/toJson` + seed data. Run app — everything still works, and you touched exactly ONE file. That's the payoff.

---

## 4. Error Handling: `try/catch` → `Either<Failure, Data>`

### GetX way

```dart
try {
  todos.value = await api.getTodos();
} catch (e) {
  Get.snackbar('Error', e.toString());  // e = ANYTHING
}
```

### Clean way (this repo)

```dart
// DataSource THROWS (data layer language):
throw const CacheException('Todo not found');
// RepositoryImpl TRANSLATES (the bridge):
} on CacheException catch (e) { return Left(CacheFailure(e.message)); }
// UseCase PASSES THROUGH: return repository.getTodos();
// Bloc FOLDS (domain language → UI state):
result.fold(
  (failure) => emit(state.copyWith(status: TodoStatus.error, errorMessage: failure.message)),
  (todos)   => emit(state.copyWith(status: TodoStatus.loaded, todos: todos)),
);
// UI REACTS: BlocListener shows Snackbar on error status.
```

`Either` forces both branches — the compiler won't let you forget errors. `Left` = failure path, `Right` = success path (“right = correct”).

**Exercise 4:** submit an EMPTY todo in the app. `AddTodo` UseCase returns `Left(ValidationFailure)` → error Snackbar, list preserved. Now find where that string is defined (`todo_usecases.dart`) and change it. One source of truth.

---

## 5. Dependency Injection: `Get.put` → `get_it`

| GetX | get_it (this repo) |
|---|---|
| `Get.put(CounterController())` | `sl.registerFactory(() => TodoBloc(...))` in `injection_container.dart` |
| `Get.find<TodoController>()` | `sl<TodoBloc>()` |
| `Get.putAsync(...)` / Bindings | `await di.init()` in `main()` before `runApp` |
| `Get.delete()` / SmartManagement | `BlocProvider` auto-disposes on pop; singletons live for app lifetime |

Rules: **Factory** (new copy each time) for Blocs + UseCases. **LazySingleton** (one shared) for Repository + DataSource. Order: leaf first (DataSource → Repository → UseCase → Bloc).

**Exercise 5:** add a `ClearCompleted` feature yourself (the repo is ready for it):
1. Add `clearCompleted()` to `TodoRepository` + impl + datasource.
2. Add `ClearCompleted extends UseCase<int, NoParams>` (returns deleted count).
3. Register in `injection_container.dart`, inject into `TodoBloc`, add `TodoCleared` event + handler.
4. Add a toolbar button in `TodoPage`. If you can do this without touching Entity/Model, you understand Clean Arch.

---

## 6. State Design: When to Use Which Style

This repo shows BOTH:

* **Counter style — single value** (`CounterState(count)`): tiny screens, one field.
* **Todo style — status enum + data** (`TodoState(status, todos, errorMessage)`): lists/forms that must SURVIVE errors (old list stays visible + Snackbar overlays). Used by ~90% of real screens.
* **(Commented in `todo_state.dart`) sealed-class style** (`TodoLoading/TodoLoaded/TodoError`): full-screen swaps (login → home). Better when states are mutually exclusive.

`copyWith` + `Equatable.props` in every state. No exceptions.

---

## 7. Testing Map (why companies pay for this structure)

```
GetX MVC:  test needs GetX + widgets (controller imports Flutter).
Clean:     Entity/UseCase/Repository tests = pure `dart test`, no Flutter.
  • Entity:   Todo('x').toggleDone().isDone == true
  • UseCase:  AddTodo(fakeRepo)(AddTodoParams('')) == Left(ValidationFailure)
  • Bloc:     blocTest('emits [loading, loaded]', build: ..., act: add(Requested), expect: ...)
  • Widget:   pump TodoPage with fake Bloc, tap checkbox, verify event.
```

Try: `flutter test` still passes (counter smoke test was replaced — add `bloc_test` + `mocktail` dev deps when ready).

---

## 8. GetX → BLoC Translation Table (tape to monitor)

| GetX / MVC | BLoC + Clean Arch (this repo) |
|---|---|
| `class C extends GetxController` | `class TodoBloc extends Bloc<TodoEvent, TodoState>` |
| `var x = 0.obs` | `TodoState(status:…, todos:…)` (immutable snapshot) |
| `x.value++` / `update()` | `emit(state.copyWith(...))` |
| `Obx(() => …)` / `GetBuilder` | `BlocBuilder<B, S>(builder: …)` |
| `ever(x, (_) => …)` / workers | `BlocListener` / `BlocObserver` |
| `Get.snackbar` in controller | `Listener` shows `SnackBar` from error state |
| `onInit() { fetch(); }` | `sl<Bloc>()..add(Requested())` |
| `Get.put` / `Get.find` | `sl.registerFactory/LazySingleton` / `sl<T>()` |
| `Get.to(Page())` | `context.push(...)` (go_router; Bloc never navigates — Listener does) |
| `Get.toNamed('/products/5')` | `context.push('/products/5', extra: cache)` (deep-linkable URL) |
| `GetConnect` / `http` + `print(body)` | `Dio` singleton + `LogInterceptor` (auto-logs every call) |
| `if (res.hasError)` per call | ONE `_mapDioError` table in RepositoryImpl |
| Model with `fromJson` + API calls | `Entity` (pure) + `Model.fromJson` + `DataSource` + `RepositoryImpl` |
| `try/catch (e)` | `Either<Failure, Data>` + `fold(Left, Right)` |
| `GetStorage` / `http` in controller | `DataSource` (only class touching I/O) |

---

## 9. Suggested Learning Order (3–4 hours)

1. **Counter trio** (30 min): `counter_event.dart` → `counter_state.dart` → `counter_bloc.dart` → `counter_page.dart`. Press buttons. Watch console (AppBlocObserver is ON).
2. **Todo trace** (45 min): follow §3's 6-hop trace in code. Read each file's header comment.
3. **Break things** (30 min): do Exercises 1–4. Empty-todo validation, JSON rename, `read`→`watch`.
4. **Shop trace** (45 min): read §11 + §12, then trace `ProductsRequested` through Dio logs in console. Tap a product → detail paints instantly from `extra`, then revalidates.
5. **Build** (45 min): Exercise 5 (`ClearCompleted`), then Exercise 6 (cart Cubit).
6. **Test** (bonus): add `bloc_test` + `mocktail`, write one UseCase test + one Bloc test.

---

## 11. Real API with Dio (the Shop feature)

Screen **3. Shop** fetches live products from FakeStoreAPI. Same Clean Arch shape as Todo — only the DataSource changes from memory-Map to Dio:

```
Todo:     TodoLocalDataSource (Map)  ─┐
Shop:     ProductRemoteDataSource (Dio) ─┤→ RepositoryImpl → UseCase → Bloc → UI
```

### Dio setup (`lib/core/network/`)

- `api_constants.dart` — base URL + endpoint paths. Only file with hardcoded URLs.
- `dio_client.dart` — `createDio()`: baseUrl, 15s timeouts, `LogInterceptor` (every request printed with `🌐 DIO ›`), JSON defaults. Registered once as `sl<Dio>()` singleton; all datasources share it. Auth template (token header + 401 refresh-and-retry) is commented at the bottom.

### JSON quirks (`product_model.dart`) — memorize these two

```dart
price: (json['price'] as num).toDouble(),  // API sends 22 AND 109.95 — `as double` crashes on int
rating: (ratingJson['rate'] as num? ?? 0).toDouble(),  // nested {rate,count} flattened
```

### Typed network errors (`product_repository_impl.dart`)

| Dio throws | Repo emits |
|---|---|
| timeout (`connectionTimeout`/`receiveTimeout`) | `ServerFailure('Request timed out…')` |
| `connectionError` (no internet) | `ServerFailure('No internet connection…')` |
| 404 | `ServerFailure('…not found')` |
| 401 / 5xx | session-expired / server-error message |
| anything else | `UnexpectedFailure` |

### List UX states (`products_page.dart`)

- First load + empty → shimmer skeletons (`AppLoadingList`)
- Error + empty → `AppErrorView` + Retry (re-sends `ProductsRequested`)
- Data (fresh or stale) → category chips + `RefreshIndicator` list
- Error + stale data → list stays + Snackbar (never blank the screen)
- Pull-to-refresh emits no `loading` — spinner via `isRefreshing` flag

### Two Blocs, not one

`ProductsBloc` (catalogue: filter + refresh) and `ProductDetailBloc` (one product by id) have independent lifecycles — detail dies on back-press, list keeps its scroll/filter state. Detail accepts an optional `cached` product from the list (`extra`) for instant paint, then always revalidates from network.

**Exercise 6:** add a cart — `CartCubit` (methods, no events: `add(product)`, `remove(id)`) provided above `MaterialApp.router`, badge in `ProductsPage` AppBar via `BlocBuilder`, total via entity helper. Cubit is the right tool here (tiny shared state, no async).

---

## 12. Navigation: go_router + BLoC rules

**Short answer: yes, use go_router** (already wired — `lib/core/router/app_router.dart`). It's the Flutter team's declarative router: URL-based, deep-linkable (`/products/5` opens detail from a pasted link), `debugLogDiagnostics: true` logs every navigation. `auto_route` is the codegen alternative; GetX routing couples navigation to controller lifecycle and fights `BlocProvider` disposal — avoid mixing.

```dart
context.push('/products/5', extra: product);  // detail on top, back returns
context.go('/products');                      // replace stack (tabs, logout)
context.pop();                                // back
```

Rules (enforced in code, explained in `app_router.dart` header):

1. **Router creates PAGES, pages create BLOCS.** `BlocProvider` lives in page files, never in the router.
2. **Primitives via path params, objects via `extra` as cache hints only.** Detail refetches by id — deep links have no `extra`.
3. **Blocs never navigate.** Emit state → `BlocListener` calls `context.go/push`. (Bloc importing a router = untestable.)
4. Routes: `/` home, `/counter`, `/todos`, `/products`, `/products/:id`, plus an error page for unknown URLs.

**Try:** run on web/chrome, open `/products`, tap item (URL becomes `/products/5`), copy URL into a new tab — detail loads standalone (spinner, no cache, same Bloc path).

---

## 13. FAQ (from GetX devs)

**“Isn't this 10× more files for the same todo app?”**
Yes — for a 2-screen app. The payoff starts at screen 5, when GetX controllers import each other and `update()` rebuilds half the app. Clean Arch's boundaries keep features independent: delete `features/todo/` and the app still compiles.

**“Can I use BLoC without Clean Architecture?”**
Absolutely — Counter does exactly that (Bloc + UI, no layers). Add UseCases/Repositories when logic outgrows the Bloc file (~200 lines is the smell).

**“Can I keep GetX for navigation/snackbar and use Bloc for state?”**
Yes, common migration path: `Get.to()`, `Get.snackbar` stay; controllers become Blocs one screen at a time.

**“Cubit or Bloc?”**
Cubit = Bloc without Events (call methods directly: `bloc.increment()`). Less boilerplate, less traceability. Learn Bloc first (this repo); Cubit is a 10-minute downgrade later. Rule: team > 2 or complex flows → Bloc; solo tiny widget state → Cubit.

**“Where do globals (auth token, theme) go?”**
`AuthBloc` / `ThemeCubit` provided ABOVE `MaterialApp` via `MultiBlocProvider` in `main.dart`. Same as `Get.put(..., permanent: true)`.

---

*End of guide. Now close this file and read `lib/features/counter/presentation/bloc/counter_bloc.dart` — it's 60 lines and contains the entire pattern.*
