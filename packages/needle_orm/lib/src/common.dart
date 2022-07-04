/// a helper extension.
extension Apply<T> on T {
  /// a helper method, to call a closure with itself as the parameter.
  T apply(Function(T) fun) {
    fun(this);
    return this;
  }
}
