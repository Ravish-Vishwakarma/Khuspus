import 'dart:io';
import 'package:path/path.dart' as p;

String getDatabasePath() {
  final exeDir = File(Platform.resolvedExecutable).parent;
  return p.join(exeDir.path, 'khuspus.db');
}
