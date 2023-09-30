import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/style_state.dart';

typedef GetSaveCommand = BaseDbCmd Function(bool newValue);

class PropertyBoolView extends StatefulWidget {
  final String title;
  final bool value;
  final GetSaveCommand saveCallback;

  PropertyBoolView({
    Key? key,
    required this.title,
    required this.value,
    required this.saveCallback,
  }) : super(key: key ?? ValueKey('$title:$value'));

  @override
  State<PropertyBoolView> createState() => _PropertyBoolViewState();
}

class _PropertyBoolViewState extends State<PropertyBoolView> {
  late bool value;

  @override
  void initState() {
    super.initState();
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30 * kScale,
      child: Row(
        children: [
          kStyle.wrapCheckbox(
            Checkbox(
              value: value,
              onChanged: _handleValueChanged,
            ),
          ),
          Expanded(
            child: Text(
              widget.title,
              style: kStyle.kTextExtraSmallPropertyHeader,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _saveIdIfRequired() {
    if (value == widget.value) //
      return;
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(widget.saveCallback(value));
  }

  void _handleValueChanged(bool? value) {
    setState(() {
      this.value = value ?? false;
      _saveIdIfRequired();
    });
  }
}
