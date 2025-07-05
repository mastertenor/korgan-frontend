// lib/src/core/utils/result.dart

import '../error/failures.dart' as failures;

/// Result wrapper for operations that can succeed or fail
///
/// This sealed class represents the outcome of an operation that can either
/// succeed with data of type [T] or fail with a [Failure].
/// It provides a type-safe way to handle success and error cases.
sealed class Result<T> {
  const Result();

  /// Check if the result is a success
  bool get isSuccess => this is Success<T>;

  /// Check if the result is a failure
  bool get isFailure => this is Failure<T>;

  /// Get the data if success, null if failure
  T? get data => switch (this) {
    Success<T>(data: final data) => data,
    Failure<T>() => null,
  };

  /// Get the failure if failure, null if success
  failures.Failure? get failure => switch (this) {
    Success<T>() => null,
    Failure<T>(failure: final failure) => failure,
  };

  /// Get the error message if failure, null if success
  String? get errorMessage => switch (this) {
    Success<T>() => null,
    Failure<T>(failure: final failure) => failure.message,
  };

  /// Execute different functions based on the result type
  R when<R>({
    required R Function(T data) success,
    required R Function(failures.Failure failure) failure,
  }) {
    return switch (this) {
      Success<T>(data: final data) => success(data),
      Failure<T>(failure: final f) => failure(f),
    };
  }

  /// Execute functions based on result type (void version)
  void whenOrNull({
    void Function(T data)? success,
    void Function(failures.Failure failure)? failure,
  }) {
    switch (this) {
      case Success<T>(data: final data):
        success?.call(data);
      case Failure<T>(failure: final f):
        failure?.call(f);
    }
  }

  /// Transform the data if success, keep failure unchanged
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => Success(transform(data)),
      Failure<T>(failure: final failure) => Failure(failure),
    };
  }

  /// Transform the data asynchronously if success
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    return switch (this) {
      Success<T>(data: final data) => Success(await transform(data)),
      Failure<T>(failure: final failure) => Failure(failure),
    };
  }

  /// Chain multiple operations that return Result
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => transform(data),
      Failure<T>(failure: final failure) => Failure(failure),
    };
  }

  /// Chain multiple async operations that return Result
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T data) transform,
  ) async {
    return switch (this) {
      Success<T>(data: final data) => await transform(data),
      Failure<T>(failure: final failure) => Failure(failure),
    };
  }

  /// Filter the success data based on a predicate
  Result<T> where(
    bool Function(T data) predicate,
    failures.Failure Function() onFilterFailed,
  ) {
    return switch (this) {
      Success<T>(data: final data) =>
        predicate(data) ? this : Failure(onFilterFailed()),
      Failure<T>() => this,
    };
  }

  /// Get the data or throw the failure as an exception
  T getOrThrow() {
    return switch (this) {
      Success<T>(data: final data) => data,
      Failure<T>(failure: final failure) => throw Exception(failure.message),
    };
  }

  /// Get the data or return a default value
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success<T>(data: final data) => data,
      Failure<T>() => defaultValue,
    };
  }

  /// Get the data or compute a default value from the failure
  T getOrElseFrom(T Function(failures.Failure failure) defaultValue) {
    return switch (this) {
      Success<T>(data: final data) => data,
      Failure<T>(failure: final failure) => defaultValue(failure),
    };
  }

  /// Recover from failure by providing an alternative result
  Result<T> recover(Result<T> Function(failures.Failure failure) recovery) {
    return switch (this) {
      Success<T>() => this,
      Failure<T>(failure: final failure) => recovery(failure),
    };
  }

  /// Recover from failure asynchronously
  Future<Result<T>> recoverAsync(
    Future<Result<T>> Function(failures.Failure failure) recovery,
  ) async {
    return switch (this) {
      Success<T>() => this,
      Failure<T>(failure: final failure) => await recovery(failure),
    };
  }

  /// Convert to a nullable value (null if failure)
  T? toNullable() => data;

  /// Convert to a list (empty if failure, single item if success)
  List<T> toList() {
    return switch (this) {
      Success<T>(data: final data) => [data],
      Failure<T>() => [],
    };
  }

  @override
  String toString() {
    return switch (this) {
      Success<T>(data: final data) => 'Success($data)',
      Failure<T>(failure: final failure) => 'Failure($failure)',
    };
  }
}

/// Represents a successful operation result
final class Success<T> extends Result<T> {
  @override
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}

/// Represents a failed operation result
final class Failure<T> extends Result<T> {
  @override
  final failures.Failure failure;

  const Failure(this.failure);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure<T> && other.failure == failure;
  }

  @override
  int get hashCode => failure.hashCode;
}

// ignore: unintended_html_in_doc_comment
/// Extension methods for working with Future<Result<T>>
extension FutureResultExtension<T> on Future<Result<T>> {
  /// Map the success value asynchronously
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    final result = await this;
    return result.mapAsync(transform);
  }

  /// Chain async operations
  Future<Result<R>> flatMapAsync<R>(
    Future<Result<R>> Function(T data) transform,
  ) async {
    final result = await this;
    return result.flatMapAsync(transform);
  }

  /// Handle the result when the future completes
  Future<R> whenAsync<R>({
    required Future<R> Function(T data) success,
    required Future<R> Function(failures.Failure failure) failure,
  }) async {
    final result = await this;
    return result.when(
      success: (data) => success(data),
      failure: (f) => failure(f),
    );
  }

  /// Get data or default value asynchronously
  Future<T> getOrElseAsync(T defaultValue) async {
    final result = await this;
    return result.getOrElse(defaultValue);
  }

  /// Recover from failure asynchronously
  Future<Result<T>> recoverAsync(
    Future<Result<T>> Function(failures.Failure failure) recovery,
  ) async {
    final result = await this;
    return result.recoverAsync(recovery);
  }

  /// Convert future result to nullable
  Future<T?> toNullableAsync() async {
    final result = await this;
    return result.toNullable();
  }
}

/// Utility functions for working with Results
class ResultUtils {
  ResultUtils._();

  /// Combine multiple results into a single result containing a list
  static Result<List<T>> combine<T>(List<Result<T>> results) {
    final List<T> successData = [];

    for (final result in results) {
      switch (result) {
        case Success<T>(data: final data):
          successData.add(data);
        case Failure<T>(failure: final failure):
          return Failure<List<T>>(failure);
      }
    }

    return Success(successData);
  }

  /// Execute multiple async operations and combine their results
  static Future<Result<List<T>>> combineAsync<T>(
    List<Future<Result<T>>> futures,
  ) async {
    final results = await Future.wait(futures);
    return combine(results);
  }

  /// Execute operations in parallel and return the first successful result
  static Future<Result<T>> raceSuccess<T>(
    List<Future<Result<T>>> futures,
  ) async {
    final results = await Future.wait(futures);

    for (final result in results) {
      if (result.isSuccess) {
        return result;
      }
    }

    // If no success, return the first failure
    return results.first;
  }

  /// Try multiple operations in sequence until one succeeds
  static Future<Result<T>> trySequential<T>(
    List<Future<Result<T>> Function()> operations,
  ) async {
    for (final operation in operations) {
      final result = await operation();
      if (result.isSuccess) {
        return result;
      }
    }

    // If all fail, return the last failure
    return await operations.last();
  }

  /// Convert a function that might throw to a Result
  static Result<T> fromTry<T>(T Function() operation) {
    try {
      return Success(operation());
    } catch (e) {
      return Failure<T>(failures.AppFailure.unknown(message: e.toString()));
    }
  }

  /// Convert an async function that might throw to a Result
  static Future<Result<T>> fromTryAsync<T>(
    Future<T> Function() operation,
  ) async {
    try {
      final data = await operation();
      return Success(data);
    } catch (e) {
      return Failure<T>(failures.AppFailure.unknown(message: e.toString()));
    }
  }

  /// Convert a nullable value to a Result
  static Result<T> fromNullable<T>(
    T? value,
    failures.Failure Function() onNull,
  ) {
    return value != null ? Success(value) : Failure<T>(onNull());
  }

  /// Convert a boolean to a Result
  static Result<void> fromBool(
    bool condition,
    failures.Failure Function() onFalse,
  ) {
    return condition ? const Success(null) : Failure<void>(onFalse());
  }
}

/// Type aliases for common Result types
typedef VoidResult = Result<void>;
typedef StringResult = Result<String>;
typedef IntResult = Result<int>;
typedef BoolResult = Result<bool>;
typedef ListResult<T> = Result<List<T>>;
typedef MapResult<K, V> = Result<Map<K, V>>;

/// Extension for easy Result creation
extension ResultCreation<T> on T {
  /// Wrap value in a Success result
  Result<T> toSuccess() => Success(this);
}

extension FailureCreation on failures.Failure {
  /// Wrap failure in a Result
  Result<T> toResult<T>() => Failure<T>(this);
}
