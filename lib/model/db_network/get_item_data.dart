import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db_network/commands_common.dart';
import 'package:gceditor/model/state/server_git_state.dart';
import 'package:json_annotation/json_annotation.dart';

part 'get_item_data.g.dart';

@JsonSerializable()
class GitItemData {
  late final String id;
  late final String name;
  late final String branchName;
  late final GitItemType? type;

  GitItemData();
  GitItemData.values({
    required this.id,
    required this.name,
    required this.branchName,
    required this.type,
  });

  GitItemData.fromItem(GitItem item)
      : id = item.id,
        name = item.name,
        branchName = item.branchName,
        type = item.type;

  @JsonKey(ignore: true)
  Color get color {
    switch (type) {
      case GitItemType.undefined:
      case GitItemType.project:
        return kTextColorLightest;

      case GitItemType.authList:
        return kTextColorLightest;

      case GitItemType.generator:
        return kTextColorLight2;

      case GitItemType.history:
        return kTextColorLight3;

      case null:
        throw Exception('Unexpected git item type null');
    }
  }

  factory GitItemData.fromJson(Map<String, dynamic> json) => _$GitItemDataFromJson(json);
  Map<String, dynamic> toJson() => _$GitItemDataToJson(this);
}
