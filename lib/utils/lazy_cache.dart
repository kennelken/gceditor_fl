import 'package:collection/collection.dart';

typedef GetValue<K, V> = V? Function(K key);
typedef GetValueByList<K, V> = V? Function(Iterable<V> list, K key);

class LazyCache<K, V> {
  late final GetValue<K, V?> _getValue;
  late final LazyCachePreCacheParams<K>? _preCache;

  late final _cachedValues = <K, V?>{};
  bool _precached = false;

  LazyCache(GetValue<K, V> getValue, {LazyCachePreCacheParams<K>? preCache}) {
    _getValue = getValue;
    _preCache = preCache;

    _doPreCache(true);
  }

  factory LazyCache.byList(
    Iterable<V> list,
    GetValue<V, K> getKey, {
    GetValueByList<K, V>? getValueByList,
    bool preCache = true,
    bool preCacheLazy = true,
  }) {
    getValueByList ??= (l, i) => l.firstWhereOrNull((e) => getKey(e) == i);
    final result = LazyCache<K, V>(
      (k) => getValueByList!(list, k),
      preCache: preCache ? LazyCachePreCacheParams(keys: list.map((e) => getKey(e)!).toList(), lazy: preCacheLazy) : null,
    );
    return result;
  }

  V? get(K key) {
    _doPreCache(false);

    if (!_cachedValues.containsKey(key)) {
      _cachedValues[key] = _getValue(key);
    }
    return _cachedValues[key];
  }

  void invalidate({bool preCache = true}) {
    _precached = false;
    _cachedValues.clear();
    _doPreCache(true);
  }

  void _doPreCache(bool initial) {
    if (!_precached && _preCache != null) {
      if (!_preCache!.lazy || !initial) {
        _precached = true;
        for (final key in _preCache!.keys) {
          get(key);
        }
      }
    }
  }
}

class LazyCachePreCacheParams<T> {
  Iterable<T> keys;
  bool lazy;

  LazyCachePreCacheParams({required this.keys, this.lazy = true});
}
