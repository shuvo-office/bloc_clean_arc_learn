// ═══════════════════════════════════════════════════════════════════════════
// CORE > ERROR > FAILURES
// ═══════════════════════════════════════════════════════════════════════════
// WHAT IS THIS FILE?
// ─────────────────
// In Clean Architecture, DOMAIN layer never throws raw Exceptions.
// It returns a `Failure` object wrapped in Either<Failure, Success>.
//
// WHY?
// ────
// GetX/MVC way (you are used to):
//   try { ... } catch (e) { snackbar("Error: $e") }
//   Problem: `e` can be ANYTHING — String, SocketException, FirebaseException.
//   UI has to guess what went wrong.
//
// Clean Arch way:
//   Repository always returns Either<Failure, Data>.
//   Left  = a KNOWN failure type (ServerFailure, CacheFailure, ...)
//   Right = success data
//   UI / Bloc only handles KNOWN types. No surprises.
//
// COMPARISON:
//   GetX Controller : `RxString error = ''.obs`
//   Clean Arch      : `Left(ServerFailure('500'))` — typed, testable.
//
// ───────────────────────────────────────────────────────────────────────────
import 'package:equatable/equatable.dart';

/// Base class for ALL failures in the app.
///
/// Extends Equatable so `ServerFailure('x') == ServerFailure('x')` is TRUE.
/// (Without Equatable, Dart compares by memory address → always false.)
abstract class Failure extends Equatable {
  // Human-readable message, shown in UI if needed.
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// ─── CONCRETE FAILURES ──────────────────────────────────────────────────────
// Add one per error KIND, not per error INSTANCE.
// Rule of thumb: one per DataSource type + validation.

/// Thrown when local storage / in-memory datasource fails.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache failure']);
}

/// Thrown when server / API call fails.
/// In this learning project we have no real API, but keep it for reference
/// so you see the pattern when you add http later.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server failure']);
}

/// Thrown when user input is invalid (empty todo title, etc.)
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid input']);
}

// ─── UNEXPECTED / FALLBACK ──────────────────────────────────────────────────
/// Catch-all for bugs you didn't anticipate.
/// Bloc will map this to "Something went wrong" UI state.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error']);
}
