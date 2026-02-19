import 'package:khuspus/db/database.dart';

Future<int> insertMemory({
  required String before,
  required String after,
}) async {
  final db = await AppDatabase.get();

  return await db.insert('memories', {'before': before, 'after': after});
}

Future<List<Map<String, dynamic>>> loadMemories() async {
  final db = await AppDatabase.get();

  return await db.query('memories', orderBy: 'id DESC');
}

Future<void> deleteMemory(int id) async {
  final db = await AppDatabase.get();

  await db.delete('memories', where: 'id = ?', whereArgs: [id]);
}

getMemeoryList() async {
  var listofmem = "";
  final memories = await loadMemories();
  for (final mem in memories) {
    listofmem += "${mem["before"]} = ${mem["after"]}\n";
  }

  return listofmem;
}
