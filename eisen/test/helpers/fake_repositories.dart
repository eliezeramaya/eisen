class InMemoryRepository<T> {
  InMemoryRepository([Iterable<T>? initial])
      : _items = List<T>.of(initial ?? <T>[]);

  final List<T> _items;

  List<T> get items => List<T>.unmodifiable(_items);

  void add(T item) => _items.add(item);

  void clear() => _items.clear();
}
