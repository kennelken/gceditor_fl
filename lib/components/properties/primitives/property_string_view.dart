import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/db_cmd/base_db_cmd.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/style_state.dart';

typedef GetSaveCommand = BaseDbCmd Function(String newValue);

class PropertyStringView extends StatefulWidget {
  final String title;
  final String value;
  final String? defaultValue;
  final GetSaveCommand saveCallback;
  final bool multiline;
  final bool canBeEmpty;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? inputDecoration;
  final bool? showFindIcon;

  PropertyStringView({
    Key? key,
    required this.title,
    required this.value,
    this.defaultValue,
    required this.saveCallback,
    this.multiline = false,
    this.canBeEmpty = true,
    this.inputFormatters,
    this.inputDecoration,
    this.showFindIcon,
  }) : super(key: key ?? ValueKey('$title:$value'));

  @override
  State<PropertyStringView> createState() => _PropertyStringViewState();
}

class _PropertyStringViewState extends State<PropertyStringView> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _textController.text = widget.value;

    _textFocus.addListener(() {
      if (_textFocus.hasFocus) {
        DbModelUtils.selectAllIfDefault(_textController, widget.defaultValue);
        DbModelUtils.selectAllIfDefaultId(_textController);
        return;
      }

      _saveIfRequired();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: (widget.inputDecoration ?? kStyle.kInputTextStyleProperties).copyWith(labelText: widget.title, hintText: widget.value),
            controller: _textController,
            focusNode: _textFocus,
            inputFormatters: widget.inputFormatters,
            minLines: 1,
            maxLines: widget.multiline ? Config.multilinePropertyMaxLines : 1,
          ),
        ),
        if (widget.showFindIcon == true)
          IconButtonTransparent(
            size: 22 * kScale,
            icon: Icon(
              FontAwesomeIcons.search,
              color: kColorPrimaryLight,
              size: 12 * kScale,
            ),
            onClick: _handleFindClick,
          ),
      ],
    );
  }

  void _saveIfRequired() {
    if (!widget.canBeEmpty && _textController.text.isEmpty) {
      _textController.text = widget.value;
      return;
    }

    if (_textController.text == widget.value) //
      return;
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(widget.saveCallback(_textController.text));
  }

  void _handleFindClick() {
    providerContainer.read(clientFindStateProvider).findUsage(clientModel, _textController.text);
  }
}
