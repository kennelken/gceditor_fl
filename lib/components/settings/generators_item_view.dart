import 'package:flutter/material.dart';
import 'package:gceditor/components/properties/primitives/delete_button.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/config.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db/generator_csharp.dart';
import 'package:gceditor/model/db/generator_json.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';

class GeneratorsItemView extends StatefulWidget {
  final ValueChanged<BaseGenerator> onChange;
  final VoidCallback onDelete;
  final BaseGenerator generator;
  final int index;

  static get itemHeight => 30.0 * kScale;
  static get itemPadding => 4.0 * kScale;
  static get itemTotalHeight => (itemHeight + 2 * itemPadding) * kScale;

  const GeneratorsItemView({
    super.key,
    required this.generator,
    required this.index,
    required this.onChange,
    required this.onDelete,
  });

  @override
  GeneratorsItemViewState createState() => GeneratorsItemViewState();
}

class GeneratorsItemViewState extends State<GeneratorsItemView> {
  late BaseGenerator _generatorCopy;
  late TextEditingController _fileNameController;
  late FocusNode _fileNameFocusNode;
  late TextEditingController _fileExtensionController;
  late FocusNode _fileExtensionFocusNode;
  late TextEditingController _indentationController;
  late FocusNode _indentationFocusNode;
  late TextEditingController _namespaceController;
  late FocusNode _namespaceFocusNode;
  late TextEditingController _prefixController;
  late FocusNode _prefixFocusNode;
  late TextEditingController _prefixInterfaceController;
  late FocusNode _prefixInterfaceFocusNode;
  late TextEditingController _postfixController;
  late FocusNode _postfixFocusNode;

  @override
  void initState() {
    super.initState();

    _fileNameController = TextEditingController();
    _fileNameFocusNode = FocusNode();
    _fileNameFocusNode.addListener(_handleFileNameFocusChanged);

    _fileExtensionController = TextEditingController();
    _fileExtensionFocusNode = FocusNode();
    _fileExtensionFocusNode.addListener(_handleFileExtensionFocusChanged);

    _indentationController = TextEditingController();
    _indentationFocusNode = FocusNode();
    _indentationFocusNode.addListener(_handleIndentationFocusChanged);

    _namespaceController = TextEditingController();
    _namespaceFocusNode = FocusNode();
    _namespaceFocusNode.addListener(_handleNamespaceFocusChanged);

    _prefixController = TextEditingController();
    _prefixFocusNode = FocusNode();
    _prefixFocusNode.addListener(_handlePrefixFocusChanged);

    _prefixInterfaceController = TextEditingController();
    _prefixInterfaceFocusNode = FocusNode();
    _prefixInterfaceFocusNode.addListener(_handlePrefixInterfaceFocusChanged);

    _postfixController = TextEditingController();
    _postfixFocusNode = FocusNode();
    _postfixFocusNode.addListener(_handlePostfixFocusChanged);

    providerContainer.read(clientStateProvider).addListener(_handleClientStateChange);

    _handleClientStateChange();
  }

  @override
  void deactivate() {
    super.deactivate();

    _fileNameFocusNode.removeListener(_handleFileNameFocusChanged);
    _indentationFocusNode.removeListener(_handleIndentationFocusChanged);
    _namespaceFocusNode.removeListener(_handleNamespaceFocusChanged);
    _prefixFocusNode.removeListener(_handlePrefixFocusChanged);
    _prefixInterfaceFocusNode.removeListener(_handlePrefixInterfaceFocusChanged);
    _postfixFocusNode.removeListener(_handlePostfixFocusChanged);
    providerContainer.read(clientStateProvider).removeListener(_handleClientStateChange);
  }

  @override
  void dispose() {
    super.dispose();
    _fileNameController.dispose();
    _indentationController.dispose();
    _namespaceController.dispose();
    _prefixController.dispose();
    _prefixInterfaceController.dispose();
    _postfixController.dispose();
  }

  void _handleClientStateChange() {
    _generatorCopy = BaseGenerator.decode(BaseGenerator.encode(widget.generator).clone());
    _fileNameController.text = _generatorCopy.fileName;
    _fileExtensionController.text = _generatorCopy.fileExtension;

    switch (_generatorCopy.$type!) {
      case GeneratorType.undefined:
        throw Exception('Unexpected generator type "${_generatorCopy.$type!.name}"');

      case GeneratorType.json:
        _indentationController.text = (_generatorCopy as GeneratorJson).indentation;
        break;

      case GeneratorType.csharp:
      case GeneratorType.java:
        _namespaceController.text = (_generatorCopy as GeneratorCsharp).namespace;
        _prefixController.text = (_generatorCopy as GeneratorCsharp).prefix;
        _prefixInterfaceController.text = (_generatorCopy as GeneratorCsharp).prefixInterface;
        _postfixController.text = (_generatorCopy as GeneratorCsharp).postfix;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: GeneratorsItemView.itemPadding),
      child: Container(
        height: GeneratorsItemView.itemHeight,
        color: kTextColorLightest,
        child: Padding(
          padding: EdgeInsets.only(left: 5 * kScale, right: 30 * kScale),
          child: Row(
            children: [
              Expanded(
                flex: 10,
                child: Row(
                  children: [
                    Text(
                      '${widget.index}.',
                      style: kStyle.kTextExtraSmall.copyWith(color: kTextColorDark),
                    ),
                    SizedBox(width: 4 * kScale),
                    Expanded(
                      child: Text(
                        _generatorCopy.$type!.name,
                        style: kStyle.kTextExtraSmall.copyWith(color: kTextColorDark),
                      ),
                    ),
                    ..._getOptions(),
                  ],
                ),
              ),
              Expanded(
                flex: 8,
                child: TooltipWrapper(
                  message: Loc.get.generatorFileNameLabel,
                  child: TextField(
                    textAlign: TextAlign.end,
                    controller: _fileNameController,
                    focusNode: _fileNameFocusNode,
                    decoration: kStyle.kInputTextStyleSettingsProperties.copyWith(
                      hintText: Loc.get.generatorFileNameLabel,
                      hintStyle: kStyle.kTextExtraSmall.copyWith(
                        color: kColorPrimaryLight,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                  width: 100 * kScale,
                  child: TextField(
                    textAlign: TextAlign.end,
                    controller: _fileExtensionController,
                    focusNode: _fileExtensionFocusNode,
                    decoration: kStyle.kInputTextStyleSettingsProperties.copyWith(
                      hintText: Loc.get.generatorFileExtensionLabel,
                      hintStyle: kStyle.kTextExtraSmall.copyWith(
                        color: kColorPrimaryLight,
                      ),
                    ),
                  )),
              SizedBox(
                width: 20 * kScale,
                child: DeleteButton(
                  size: 17 * kScale,
                  onAction: _handleDeleteClick,
                  tooltipText: Loc.get.delete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileNameFocusChanged() {
    if (_fileNameFocusNode.hasFocus) //
      return;

    if (_generatorCopy.fileName == _fileNameController.text) //
      return;

    _generatorCopy.fileName = _fileNameController.text;
    widget.onChange(_generatorCopy);
  }

  void _handleFileExtensionFocusChanged() {
    if (_fileExtensionFocusNode.hasFocus) //
      return;

    if (_generatorCopy.fileExtension == _fileExtensionController.text) //
      return;

    _generatorCopy.fileExtension = _fileExtensionController.text;
    widget.onChange(_generatorCopy);
  }

  void _handleIndentationFocusChanged() {
    if (_indentationFocusNode.hasFocus) //
      return;

    if ((_generatorCopy as GeneratorJson).indentation == _indentationController.text) //
      return;

    (_generatorCopy as GeneratorJson).indentation = _indentationController.text;
    widget.onChange(_generatorCopy);
  }

  void _handleNamespaceFocusChanged() {
    if (_namespaceFocusNode.hasFocus) //
      return;

    if ((_generatorCopy as GeneratorCsharp).namespace == _namespaceController.text) //
      return;

    (_generatorCopy as GeneratorCsharp).namespace = _namespaceController.text;
    widget.onChange(_generatorCopy);
  }

  void _handlePrefixFocusChanged() {
    if (_prefixFocusNode.hasFocus) //
      return;

    if ((_generatorCopy as GeneratorCsharp).prefix == _prefixController.text) //
      return;

    (_generatorCopy as GeneratorCsharp).prefix = _prefixController.text;
    widget.onChange(_generatorCopy);
  }

  void _handlePrefixInterfaceFocusChanged() {
    if (_prefixInterfaceFocusNode.hasFocus) //
      return;

    if ((_generatorCopy as GeneratorCsharp).prefixInterface == _prefixInterfaceController.text) //
      return;

    (_generatorCopy as GeneratorCsharp).prefixInterface = _prefixInterfaceController.text;
    widget.onChange(_generatorCopy);
  }

  void _handlePostfixFocusChanged() {
    if (_postfixFocusNode.hasFocus) //
      return;

    if ((_generatorCopy as GeneratorCsharp).postfix == _postfixController.text) //
      return;

    (_generatorCopy as GeneratorCsharp).postfix = _postfixController.text;
    widget.onChange(_generatorCopy);
  }

  List<Widget> _getOptions() {
    switch (_generatorCopy.$type!) {
      case GeneratorType.undefined:
        throw Exception('Unexpected generator type "${_generatorCopy.$type!}"');

      case GeneratorType.json:
        return [
          TooltipWrapper(
            message: Loc.get.indentationLabel,
            child: SizedBox(
              width: 100 * kScale,
              child: TextField(
                clipBehavior: Clip.none,
                controller: _indentationController,
                focusNode: _indentationFocusNode,
                inputFormatters: Config.filterIndentationForJson,
                decoration: kStyle.kInputTextStyleSettingsProperties.copyWith(
                  hintText: Loc.get.indentationLabel,
                  hintStyle: kStyle.kTextUltraSmall.copyWith(
                    color: kColorPrimaryLight,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 5 * kScale),
        ];

      case GeneratorType.csharp:
      case GeneratorType.java:
        return [
          TooltipWrapper(
            message: Loc.get.namespaceLabel,
            child: SizedBox(
              width: 100 * kScale,
              child: TextField(
                clipBehavior: Clip.none,
                controller: _namespaceController,
                focusNode: _namespaceFocusNode,
                inputFormatters: Config.filterNamespace,
                decoration: kStyle.kInputTextStyleSettingsProperties.copyWith(
                  hintText: Loc.get.namespaceLabel,
                  hintStyle: kStyle.kTextUltraSmall.copyWith(
                    color: kColorPrimaryLight,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 5 * kScale),
          TooltipWrapper(
            message: Loc.get.prefixLabel,
            child: SizedBox(
              width: 100 * kScale,
              child: TextField(
                clipBehavior: Clip.none,
                controller: _prefixController,
                focusNode: _prefixFocusNode,
                inputFormatters: Config.filterId,
                decoration: kStyle.kInputTextStyleSettingsProperties.copyWith(
                  hintText: Loc.get.prefixLabel,
                  hintStyle: kStyle.kTextUltraSmall.copyWith(
                    color: kColorPrimaryLight,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 5 * kScale),
          TooltipWrapper(
            message: Loc.get.prefixInterfaceLabel,
            child: SizedBox(
              width: 100 * kScale,
              child: TextField(
                clipBehavior: Clip.none,
                controller: _prefixInterfaceController,
                focusNode: _prefixInterfaceFocusNode,
                inputFormatters: Config.filterId,
                decoration: kStyle.kInputTextStyleSettingsProperties.copyWith(
                  hintText: Loc.get.prefixInterfaceLabel,
                  hintStyle: kStyle.kTextUltraSmall.copyWith(
                    color: kColorPrimaryLight,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 5 * kScale),
          TooltipWrapper(
            message: Loc.get.postfixLabel,
            child: SizedBox(
              width: 100 * kScale,
              child: TextField(
                clipBehavior: Clip.none,
                controller: _postfixController,
                focusNode: _postfixFocusNode,
                inputFormatters: Config.filterId,
                decoration: kStyle.kInputTextStyleSettingsProperties.copyWith(
                  hintText: Loc.get.postfixLabel,
                  hintStyle: kStyle.kTextUltraSmall.copyWith(
                    color: kColorPrimaryLight,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 5 * kScale),
        ];
    }
  }

  void _handleDeleteClick() {
    widget.onDelete();
  }
}
