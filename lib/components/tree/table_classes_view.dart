import 'package:gceditor/components/tree/base_tree_view.dart';
import 'package:gceditor/model/state/client_state.dart';

final _treeController = getTreeController();

class TableClassesView extends BaseTreeView {
  TableClassesView({super.key}) : super(treeController: _treeController, data: () => clientModel.classes);
}
