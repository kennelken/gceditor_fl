import 'dart:async';
import 'dart:math';

typedef ItemSelectedCallback = void Function(int index, bool ctrlKey, bool shiftKey);
typedef IsItemSelected = bool Function(int index);

class SelectionListController {
  final Set<int> selectedItems = {};
  final onChange = StreamController<Set<int>>();

  int? _lastSelected;
  final List<int> _prevShiftSelection = [];

  void selectItem(int index, bool ctrlKey, bool shiftKey) {
    if (shiftKey && _lastSelected != null) {
      selectedItems.removeAll(_prevShiftSelection);

      final minIndex = min(_lastSelected!, index);
      final maxIndex = max(_lastSelected!, index);

      for (var i = minIndex; i <= maxIndex; i++) {
        selectedItems.add(i);
        _prevShiftSelection.add(i);
      }
    } else {
      _prevShiftSelection.clear();
      if (ctrlKey) {
        if (selectedItems.contains(index)) {
          selectedItems.remove(index);
        } else {
          selectedItems.add(index);
          _lastSelected = index;
        }
      } else {
        selectedItems.clear();
        selectedItems.add(index);
        _lastSelected = index;
      }
    }
    dispatchChange();
  }

  void reset() {
    selectedItems.clear();
    _prevShiftSelection.clear();
    _lastSelected = null;
  }

  void dispatchChange() {
    onChange.add(selectedItems);
  }
}
