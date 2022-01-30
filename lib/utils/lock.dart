import 'dart:async';

class Lock {
  final StreamController<bool> onChanged = StreamController();

  final Set<Object> _requestors = {};

  bool get locked => _requestors.isNotEmpty;

  bool? toggle(Object requestor, bool value) {
    final oldLocked = locked;

    if (value) {
      _requestors.add(requestor);
    } else {
      _requestors.remove(requestor);
    }

    final newLocked = locked;
    if (newLocked != oldLocked) {
      onChanged.add(newLocked);
      return newLocked;
    }

    return null;
  }
}
