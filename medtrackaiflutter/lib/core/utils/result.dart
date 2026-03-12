import '../error/failures.dart';

abstract class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Error<T>;

  T get data => (this as Success<T>).value;
  Failure get failure => (this as Error<T>).error;

  R fold<R>(R Function(T data) onSuccess, R Function(Failure failure) onError) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).value);
    } else {
      return onError((this as Error<T>).error);
    }
  }
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Error<T> extends Result<T> {
  final Failure error;
  const Error(this.error);
}
