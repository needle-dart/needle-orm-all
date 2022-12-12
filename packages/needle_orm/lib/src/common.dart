/// a helper extension.
extension ApplyExtension<T> on T {
  /// a helper method, to call a closure with itself as the parameter.
  T apply(Function(T) fun) {
    fun(this);
    return this;
  }
}

extension ListExtension<T> on List<T> {
  List<T> each(Future<void> Function(T) fun) {
    for (var elem in this) {
      fun(elem);
    }
    return this;
  }
}
