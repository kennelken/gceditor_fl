import 'package:darq/darq.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/global_shortcuts.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/state/style_state.dart';

class ShortcutsView extends ConsumerWidget {
  const ShortcutsView({Key? key}) : super(key: key);

  @override
  Widget build(context, watch) {
    watch(styleStateProvider);

    final items = GlobalShortcuts.getIntents().entries.toList();

    return Container(
      width: 600 * kScale,
      height: 600 * kScale,
      color: kTextColorLightest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            alignment: Alignment.center,
            height: 50 * kScale,
            color: kColorAccentBlue2,
            child: Text(
              Loc.get.keyboardShortcutsTitle,
              style: kStyle.kTextBig,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20 * kScale),
              child: ScrollConfiguration(
                behavior: kScrollDraggable,
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Container(
                        color: kTextColorLight,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5, top: 5, bottom: 5, right: 10),
                          child: Row(
                            children: [
                              Text(
                                getIntendName(items[index].value),
                                style: kStyle.kTextSmall.copyWith(color: kColorPrimaryLighter2),
                              ),
                              const Expanded(child: SizedBox()),
                              Text(
                                items[index].key.triggers!.map((e) => getModifiers(items[index].key).append(e.keyLabel).join('+')).join(', '),
                                style: kStyle.kTextSmall.copyWith(color: kColorAccentOrange),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> getModifiers(ShortcutActivator key) {
    if (key is SingleActivator) {
      return [
        key.control ? 'Ctrl' : null,
        key.shift ? 'Shift' : null,
        key.alt ? 'Alt' : null,
      ].where((element) => element != null).cast<String>().toList();
    }
    return [];
  }

  String getIntendName(Intent intent) {
    if (intent is ToggleConsoleIntent) {
      return 'Toggle console';
    }
    if (intent is DeselectIntent) {
      return 'Deselect';
    }
    if (intent is UndoIntent) {
      return 'Undo';
    }
    if (intent is RedoIntent) {
      return 'Redo';
    }
    if (intent is FindIntent) {
      return 'Find';
    }
    if (intent is RunGeneratorsIntent) {
      return 'Run generators';
    }
    if (intent is ZoomInIntent) {
      return 'Zoom in';
    }
    if (intent is ZoomOutIntent) {
      return 'Zoom out';
    }
    if (intent is NextProblemIntent) {
      return 'Next problem';
    }
    if (intent is FindIntent) {
      return 'Find';
    }
    return '<NO NAME>';
  }
}
