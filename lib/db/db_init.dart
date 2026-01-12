import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
