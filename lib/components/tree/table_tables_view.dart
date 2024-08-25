import 'package:gceditor/components/tree/base_tree_view.dart';
import 'package:gceditor/model/state/client_state.dart';

final _treeController = getTreeController();

class TableTablesView extends BaseTreeView {
  TableTablesView({super.key}) : super(treeController: _treeController, data: () => clientModel.tables);
}
