/// Estado tipado genérico para pantallas alimentadas por ViewModels.
/// Cubre loading, success, error y empty de forma uniforme en toda la app.
sealed class ViewState<T> {
  const ViewState();

  const factory ViewState.loading() = ViewLoading<T>;
  const factory ViewState.success(T data) = ViewSuccess<T>;
  const factory ViewState.error(String message) = ViewError<T>;
  const factory ViewState.empty() = ViewEmpty<T>;

  R when<R>({
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String message) error,
    required R Function() empty,
  }) {
    final self = this;
    if (self is ViewLoading<T>) return loading();
    if (self is ViewSuccess<T>) return success(self.data);
    if (self is ViewError<T>) return error(self.message);
    if (self is ViewEmpty<T>) return empty();
    throw StateError('Unknown ViewState');
  }
}

class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

class ViewSuccess<T> extends ViewState<T> {
  final T data;
  const ViewSuccess(this.data);
}

class ViewError<T> extends ViewState<T> {
  final String message;
  const ViewError(this.message);
}

class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();
}
