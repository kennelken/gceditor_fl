import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';

class ModalBottomSheetScreen extends StatelessWidget {
  final Widget _child;

  const ModalBottomSheetScreen({required Widget child, Key? key})
      : _child = child,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF757575),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10 * kScale),
            topRight: Radius.circular(10 * kScale),
          ),
        ),
        child: _child,
      ),
    );
  }

  static void show({required BuildContext context, required Widget child}) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      builder: (c) => WillPopScope(
        onWillPop: () async => true,
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ModalBottomSheetScreen(child: child),
          ),
        ),
      ),
    );
  }
}
