import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/global_shortcuts.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/settings/generators_item_view.dart';
import 'package:gceditor/components/table/context_menu_button.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/db/db_model_shared.dart';
import 'package:gceditor/model/db_cmd/db_cmd_edit_project_settings.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/db_model_factory.dart';
import 'package:gceditor/model/state/style_state.dart';
import 'package:gceditor/utils/utils.dart';

class GeneratorsView extends StatefulWidget {
  const GeneratorsView({
    Key? key,
  }) : super(key: key);

  @override
  GeneratorsViewState createState() => GeneratorsViewState();
}

class GeneratorsViewState extends State<GeneratorsView> {
  late List<BaseGenerator> generators;
  late final CustomPopupMenuController _addNewGeneratorPopupController;
  late final ScrollController _listScrollController;

  @override
  void initState() {
    super.initState();
    generators = _cloneValues(clientModel.settings.generators!);
    _addNewGeneratorPopupController = CustomPopupMenuController();
    _listScrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    _listScrollController.dispose();
    _addNewGeneratorPopupController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kTextColorLight,
      width: 9999,
      height: 182 * kScale,
      child: Padding(
        padding: EdgeInsets.all(8.0 * kScale),
        child: Column(
          children: [
            SizedBox(
              height: 30 * kScale,
              child: Row(
                children: [
                  Text(
                    Loc.get.projectSettingsGeneratorsTitle,
                    style: kStyle.kTextRegular.copyWith(color: kColorTextButton),
                  ),
                  TooltipWrapper(
                    message: Loc.get.runGenerators,
                    child: IconButtonTransparent(
                      size: 35 * kScale,
                      icon: Icon(
                        FontAwesomeIcons.forward,
                        size: 14 * kScale,
                        color: kColorAccentBlue,
                      ),
                      onClick: _handleRunGenerators,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  TooltipWrapper(
                    message: Loc.get.createNewGeneratorTooltip,
                    child: ContextMenuButton(
                      buttons: GeneratorType.values
                          .where((e) => e != GeneratorType.undefined)
                          .map((e) => ContextMenuChildButtonData(describeEnum(e), () => _handleAddNewGenerator(e)))
                          .toList(),
                      controller: _addNewGeneratorPopupController,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Theme(
                data: kStyle.kReorderableListThemeInvisibleScrollbars,
                child: ScrollConfiguration(
                  behavior: kScrollDraggable,
                  child: ReorderableListView.builder(
                    scrollController: _listScrollController,
                    scrollDirection: Axis.vertical,
                    itemCount: generators.length,
                    onReorder: _handleGeneratorsReorder,
                    itemBuilder: (context, index) {
                      return GeneratorsItemView(
                        key: ValueKey(generators[index].hashCode),
                        generator: generators[index],
                        index: index,
                        onChange: (generator) => _handleGeneratorChanged(index, generator),
                        onDelete: () => _handleGeneratorDelete(index),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BaseGenerator> _cloneValues(List<BaseGenerator> source) {
    return source.toList();
  }

  void _handleGeneratorsReorder(int oldIndex, int newIndex) {
    setState(() {
      generators.insert(newIndex, generators[oldIndex]);
      final newIndexes = Utils.getModifiedIndexesAfterReordering(oldIndex, newIndex);
      generators.removeAt(newIndexes.oldValue!);
      _saveGeneratorsList();
    });
  }

  void _handleGeneratorChanged(int index, BaseGenerator generator) {
    setState(() {
      final generatorsCopy = _cloneValues(generators);
      generatorsCopy[index] = generator;
      generators = generatorsCopy;
      _saveGeneratorsList();
    });
  }

  void _handleGeneratorDelete(int index) {
    setState(() {
      final generatorsCopy = _cloneValues(generators);
      generatorsCopy.removeAt(index);
      generators = generatorsCopy;
      _saveGeneratorsList();
    });
  }

  _handleAddNewGenerator(GeneratorType generatorType) {
    setState(
      () {
        final generatorsCopy = _cloneValues(generators);
        generatorsCopy.add(DbModelFactory.generator(generatorType));
        generators = generatorsCopy;
        _saveGeneratorsList();

        _listScrollController.animateTo(
          GeneratorsItemView.itemTotalHeight * generators.length,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  void _saveGeneratorsList() {
    providerContainer.read(clientOwnCommandsStateProvider).addCommand(
          DbCmdEditProjectSettings.values(
            generators: generators,
          ),
        );
  }

  void _handleRunGenerators() {
    GlobalShortcuts.runGenerators();
  }
}
