import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../value_holder.dart';

class StateNotifierWrapper<T> extends StateNotifier<ValueHolder<T>> {
  late T _value;
  T get value => _value;

  StateNotifierWrapper(T state) : super(ValueHolder(state)) {
    _value = state;
  }

  void dispatchChange() {
    state = ValueHolder(value);
  }

  @override
  set state(ValueHolder<T> value) {
    // ignore: null_check_on_nullable_type_parameter
    _value = value.value!;
    super.state = value;
  }
}
