import 'dart:io';
import 'package:git/git.dart';
import 'package:path/path.dart' as path;

void main() async {
  final gitDir = await GitDir.fromExisting(Directory.current.path, allowSubdirectory: true);
  
  // Create a dummy modified file for testing
  final testFile = File('test_dummy.txt');
  await testFile.writeAsString('test');
  
  final relativePath = path.relative(testFile.path, from: await Directory(gitDir.path).resolveSymbolicLinks());
  print('Relative path: $relativePath');
  
  final pr = await gitDir.runCommand(['status', '--porcelain', relativePath]);
  print('status porcelain output: "${pr.stdout}"');
  
  final pr2 = await gitDir.runCommand(['status', '--porcelain']);
  print('full status porcelain output: "${pr2.stdout}"');
}
