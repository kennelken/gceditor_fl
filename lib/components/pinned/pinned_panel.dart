import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gceditor/components/pinned/pinned_panel_item.dart';
import 'package:gceditor/components/properties/primitives/icon_button_transparent.dart';
import 'package:gceditor/components/tooltip_wrapper.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/model/state/client_state.dart';
import 'package:gceditor/model/state/pinned_items_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class PinnedPanel extends StatefulWidget {
  const PinnedPanel({
    Key? key,
  }) : super(key: key);

  @override
  State<PinnedPanel> createState() => _PinnedPanelState();
}

class _PinnedPanelState extends State<PinnedPanel> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(context) {
    return Consumer(
      builder: (context, watch, child) {
        watch(clientStateProvider);
        watch(columnSizeChangedProvider);

        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            if (_scrollController.hasClients) //
              _scrollController.animateTo(0, duration: kScrollListDuration, curve: Curves.easeInOut);
          },
        );

        final notifier = watch(pinnedItemsStateProvider);
        final tables = notifier.state.tables;
        return Padding(
          padding: EdgeInsets.only(left: 7 * kScale, top: 7 * kScale, right: 3 * kScale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 25 * kScale,
                child: Row(
                  children: [
                    SizedBox(
                      width: 25 * kScale,
                      child: Icon(
                        FontAwesomeIcons.mapPin,
                        color: kColorPrimaryLight,
                        size: 14 * kScale,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        Loc.get.pinnedPanelTitle,
                        style: kStyle.kTextExtraSmall,
                      ),
                    ),
                    TooltipWrapper(
                      message: Loc.get.closePinnedItemsTooltip,
                      child: IconButtonTransparent(
                        icon: Icon(
                          FontAwesomeIcons.times,
                          color: kColorPrimaryLight,
                          size: 20 * kScale,
                        ),
                        onClick: () => notifier.clear(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 7 * kScale),
              ScrollConfiguration(
                behavior: kScrollDraggable,
                child: Expanded(
                  child: ListView(
                    controller: _scrollController,
                    children: tables
                        .map(
                          (e) => PinnedPanelItem(
                            table: e,
                            pinnedItems: notifier.state.items[e]!,
                          ),
                        )
                        .toList(),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
