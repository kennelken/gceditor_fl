import 'package:darq/darq.dart';

class MultidimensionalMap3<K1, K2, K3, V> {
  final _data = <K1, Map<K2, Map<K3, V>>>{};

  V? operator [](Tuple3<K1, K2, K3> p) => get(p.item0!, p.item1!, p.item2!);
  void operator []=(Tuple3<K1, K2, K3> p, V v) => set(p.item0!, p.item1!, p.item2!, v);

  void set(K1 k1, K2 k2, K3 k3, V value) {
    if (!_data.containsKey(k1)) //
      _data[k1] = <K2, Map<K3, V>>{};
    if (!_data[k1]!.containsKey(k2)) //
      _data[k1]![k2] = <K3, V>{};
    _data[k1]![k2]![k3] = value;
  }

  bool hasValue(K1 k1, K2? k2, K3? k3) {
    if (k2 != null) {
      if (k3 != null) {
        return _data[k1]?[k2]?.containsKey(k3) ?? false;
      }
      return _data[k1]?.containsKey(k2) ?? false;
    }
    return _data.containsKey(k1);
  }

  V? get(K1 k1, K2 k2, K3 k3) {
    if (!hasValue(k1, k2, k3)) //
      return null;
    return _data[k1]![k2]![k3];
  }

  void delete(K1 k1, K2? k2, K3? k3) {
    if (k2 != null) {
      if (k3 != null) {
        if (hasValue(k1, k2, k3)) //
          _data[k1]![k2]!.remove(k3);
        return;
      }
      if (hasValue(k1, k2, null)) //
        _data[k1]!.remove(k2);
      return;
    }
    if (hasValue(k1, null, null)) //
      _data.remove(k1);
    return;
  }

  Map<K1, Map<K2, Map<K3, V>>> depth0() {
    return _data;
  }

  Map<K2, Map<K3, V>>? depth1(K1 k1) {
    return _data[k1];
  }

  Map<K3, V>? depth2(K1 k1, K2 k2) {
    return _data[k1]?[k2];
  }

  void clear() {
    _data.clear();
  }

  Iterable<Tuple4<K1, K2, K3, V>> values() sync* {
    for (final p1 in _data.keys) {
      for (final p2 in _data[p1]!.keys) {
        for (final p3 in _data[p1]![p2]!.keys) {
          // ignore: null_check_on_nullable_type_parameter
          yield Tuple4(p1, p2, p3, _data[p1]![p2]![p3]!);
        }
      }
    }
  }
}

class MultidimensionalMap2<K1, K2, V> {
  final _data = <K1, Map<K2, V>>{};

  V? operator [](Tuple2<K1, K2> p) => get(p.item0!, p.item1!);
  void operator []=(Tuple2<K1, K2> p, V v) => set(p.item0!, p.item1!, v);

  void set(K1 k1, K2 k2, V value) {
    if (!_data.containsKey(k1)) //
      _data[k1] = <K2, V>{};
    _data[k1]![k2] = value;
  }

  bool hasValue(K1 k1, K2? k2) {
    if (k2 != null) {
      return _data[k1]?.containsKey(k2) ?? false;
    }
    return _data.containsKey(k1);
  }

  V? get(K1 k1, K2 k2) {
    if (!hasValue(k1, k2)) //
      return null;
    return _data[k1]![k2];
  }

  void delete(K1 k1, K2? k2) {
    if (k2 != null) {
      if (hasValue(k1, k2)) //
        _data[k1]!.remove(k2);
      return;
    }
    if (hasValue(k1, null)) //
      _data.remove(k1);
    return;
  }

  Map<K1, Map<K2, V>> depth0() {
    return _data;
  }

  Map<K2, V>? depth1(K1 k1) {
    return _data[k1];
  }

  void clear() {
    _data.clear();
  }

  Iterable<Tuple3<K1, K2, V>> values() sync* {
    for (final p1 in _data.keys) {
      for (final p2 in _data[p1]!.keys) {
        yield Tuple3(p1, p2, _data[p1]![p2]!);
      }
    }
  }
}
