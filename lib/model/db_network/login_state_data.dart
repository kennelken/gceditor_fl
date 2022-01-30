import 'package:gceditor/model/db_network/auth_list_entry.dart';
import 'package:json_annotation/json_annotation.dart';

part 'login_state_data.g.dart';

@JsonSerializable()
class LoginListData {
  Map<String, AuthListEntry> users = {};

  LoginListData();

  factory LoginListData.fromJson(Map<String, dynamic> json) => _$LoginListDataFromJson(json);
  Map<String, dynamic> toJson() => _$LoginListDataToJson(this);
}
