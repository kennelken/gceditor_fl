import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gceditor/components/table/primitives/data_table_cell_view.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/consts/loc.dart';
import 'package:gceditor/main.dart';
import 'package:gceditor/model/state/client_find_state.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/db_model_extensions.dart';
import 'package:gceditor/model/state/service/client_navigation_service.dart';
import 'package:gceditor/model/state/style_state.dart';

class DataTableCellColorView extends ConsumerWidget {
  final DataTableValueCoordinates coordinates;

  final dynamic value;
  final ValueChanged<dynamic> onValueChanged;

  const DataTableCellColorView({
    super.key,
    required this.coordinates,
    required this.value,
    required this.onValueChanged,
  });

  @override
  Widget build(context, ref) {
    final initialColor = Color(value);
    return Container(
      color: DbModelUtils.getDataCellColor(
        coordinates,
        ref.watch(clientProblemsStateProvider).state,
        ref.watch(clientFindStateProvider).state,
        ref.watch(clientNavigationServiceProvider).state,
      ),
      child: Padding(
        padding: EdgeInsets.all(8 * kScale),
        child: Material(
          color: kColorTransparent,
          child: InkWell(
            onTap: () => _showColorPicker(initialColor),
            child: ClipRRect(
              child: CustomPaint(
                painter: SquarePainter(initialColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleColorChanged(Color color) {
    if (color.value == value) //
      return;
    onValueChanged(color.value);
  }

  void _showColorPicker(Color initialColor) {
    var pickerColor = initialColor;
    final textController = TextEditingController();
    final focusNode = FocusNode();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        textController.selection = TextSelection(baseOffset: 0, extentOffset: textController.text.length);
      }
    });

    showDialog(
      context: popupContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kTextColorLightest,
          content: SingleChildScrollView(
            child: Column(
              children: [
                Theme(
                  data: kStyle.kInputThemeLight,
                  child: ColorPicker(
                    pickerColor: pickerColor,
                    onColorChanged: (color) {
                      pickerColor = color;
                    },
                    colorPickerWidth: 300 * kScale,
                    pickerAreaHeightPercent: 0.7,
                    enableAlpha: true,
                    displayThumbColor: true,
                    paletteType: PaletteType.hslWithHue,
                    labelTypes: const [ColorLabelType.rgb, ColorLabelType.hex, ColorLabelType.hsl, ColorLabelType.hsv],
                    pickerAreaBorderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2 * kScale),
                      topRight: Radius.circular(2 * kScale),
                    ),
                    hexInputBar: false,
                    hexInputController: textController,
                    portraitOnly: true,
                  ),
                ),
                Theme(
                  data: kStyle.kInputThemeLight,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16 * kScale, top: 0 * kScale, right: 16 * kScale, bottom: 16 * kScale),
                    child: TextField(
                      textAlign: TextAlign.center,
                      controller: textController,
                      focusNode: focusNode,
                      autofocus: true,
                      maxLength: 9,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        FilteringTextInputFormatter.allow(RegExp(kValidHexPattern)),
                      ],
                      decoration: const InputDecoration(counter: SizedBox()),
                      style: kStyle.kTextSmall.copyWith(color: kColorPrimaryLighter),
                    ),
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: kButtonTransparent,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  Loc.get.buttonCancel,
                  style: kStyle.kTextSmall.copyWith(color: kColorPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            TextButton(
              style: kButtonTransparent,
              onPressed: () {
                _handleColorChanged(pickerColor);
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  Loc.get.buttonApply,
                  style: kStyle.kTextSmall.copyWith(color: kColorPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Painter for chess type alpha background in color indicator widget.
class SquarePainter extends CustomPainter {
  const SquarePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final chessSize = Size(20 * kScale, 20 * kScale);
    final chessPaintB = Paint()..color = const Color(0xFFCCCCCC);
    final chessPaintW = Paint()..color = Colors.white;
    List.generate((size.height / chessSize.height).ceil(), (int y) {
      List.generate((size.width / chessSize.width).ceil(), (int x) {
        canvas.drawRect(
          Offset(chessSize.width * x, chessSize.height * y) & chessSize,
          (x + y) % 2 != 0 ? chessPaintW : chessPaintB,
        );
      });
    });

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
