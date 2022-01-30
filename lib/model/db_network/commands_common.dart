import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum GitItemType {
  undefined,
  project,
  authList,
  generator,
  history,
}
