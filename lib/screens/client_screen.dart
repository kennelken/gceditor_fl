import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/table/table_properties_view.dart';
import 'package:gceditor/components/table/table_view.dart';
import 'package:gceditor/model/state/settings_state.dart';

class ClientScreen extends ConsumerWidget {
  const ClientScreen({super.key});

  @override
  Widget build(context, ref) {
    ref.watch(settingsStateProvider);
    return const Row(
      children: [
        Expanded(child: TableView()),
        TablePropertiesView(),
      ],
    );
  }
}
