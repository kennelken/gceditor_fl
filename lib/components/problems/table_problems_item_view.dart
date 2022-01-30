import 'package:flutter/material.dart';
import 'package:gceditor/consts/consts.dart';
import 'package:gceditor/model/model_root.dart';
import 'package:gceditor/model/state/client_problems_state.dart';
import 'package:gceditor/model/state/style_state.dart';

class TableProblemsItemView extends StatelessWidget {
  final int index;
  final DbModelProblem problem;

  const TableProblemsItemView({
    Key? key,
    required this.index,
    required this.problem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26 * kScale,
      child: FittedBox(
        fit: BoxFit.none,
        alignment: Alignment.centerLeft,
        child: Material(
          color: kColorPrimaryLighter,
          child: InkWell(
            onTap: _handleProblemClick,
            child: Padding(
              padding: EdgeInsets.only(left: 5 * kScale),
              child: Row(
                children: [
                  Text(
                    '$index.',
                    style: kStyle.kTextExtraSmallInactive,
                  ),
                  SizedBox(width: 3 * kScale),
                  Text(
                    '${problem.tableId}:${problem.rowIndex}:${problem.fieldIndex}',
                    style: kStyle.kTextExtraSmall,
                  ),
                  SizedBox(width: 5 * kScale),
                  Text(
                    problem.getDescription(),
                    style: kStyle.kTextExtraSmall.copyWith(color: problem.color),
                  ),
                  Text(
                    ': "${problem.value}"',
                    style: kStyle.kTextExtraSmall,
                  ),
                  const SizedBox(width: 9999),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _handleProblemClick() {
    providerContainer.read(clientProblemsStateProvider).focusOnNextProblem(problem);
  }
}
