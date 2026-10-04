import 'package:gceditor/model/db/db_model_shared.dart';

class StringWrapper implements IIdentifiable {
  final String value;
  @override
  late String id;

  StringWrapper(this.value) {
    id = value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringWrapper && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}
