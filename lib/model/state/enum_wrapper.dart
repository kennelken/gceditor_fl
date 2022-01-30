import 'package:flutter/foundation.dart';
import 'package:gceditor/model/db/db_model_shared.dart';

class EnumWrapper<T extends Enum> implements IIdentifiable {
  final T value;
  @override
  late String id;

  EnumWrapper(this.value) {
    id = describeEnum(value);
  }
}
