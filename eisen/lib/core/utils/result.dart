sealed class Result<T> {
  const Result();
  R when<R>({required R Function(T) ok, required R Function(Object) err});
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
  @override
  R when<R>(
          {required R Function(T p1) ok, required R Function(Object p1) err}) =>
      ok(value);
}

class Err<T> extends Result<T> {
  const Err(this.error);
  final Object error;
  @override
  R when<R>(
          {required R Function(T p1) ok, required R Function(Object p1) err}) =>
      err(error);
}
