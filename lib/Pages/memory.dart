// ignore_for_file: prefer_final_fields, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:khuspus/Widgets/snackbar.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class MemoryPage extends StatefulWidget {
  const MemoryPage({super.key});

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  TextEditingController _before = TextEditingController();
  TextEditingController _after = TextEditingController();

  Future<List<Map<String, dynamic>>> loadMemoriesFromLauncher() async {
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();

    for (final id in windowIds) {
      final win = WindowManagerPlus.fromWindowId(id);
      final title = await win.getTitle();

      if (title == 'Launcher Window') {
        final result = await WindowManagerPlus.current.invokeMethodToWindow(
          id,
          "db_loadMemories",
          null,
        );

        return result
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
      }
    }

    throw Exception("Launcher window not found");
  }

  Future<dynamic> deleteMemoryFromLauncher(int tid) async {
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();

    // Find launcher window by title
    for (final id in windowIds) {
      final win = WindowManagerPlus.fromWindowId(id);
      final title = await win.getTitle();

      if (title == 'Launcher Window') {
        return await WindowManagerPlus.current.invokeMethodToWindow(
          id,
          "db_deleteMemory",
          {"id": tid},
        );
      }
    }

    throw Exception("Launcher window not found");
  }

  Future<dynamic> insertMemoryFromLauncher(String before, String after) async {
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();

    // Find launcher window by title
    for (final id in windowIds) {
      final win = WindowManagerPlus.fromWindowId(id);
      final title = await win.getTitle();

      if (title == 'Launcher Window') {
        return await WindowManagerPlus.current.invokeMethodToWindow(
          id,
          "db_insertMemory",
          {"before": before, "after": after},
        );
      }
    }

    throw Exception("Launcher window not found");
  }

  List<Map<String, dynamic>> memories = [];
  bool isLoading = true;

  Future<void> _loadMemories() async {
    final data = await loadMemoriesFromLauncher();

    if (!mounted) return;

    setState(() {
      memories = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    });
  }

  _startup() async {
    await _loadMemories();
  }

  @override
  void initState() {
    super.initState();
    _startup();
  }

  @override
  Widget build(BuildContext context) {
    late List<DataRow> memoryRows = memories.map((memory) {
      return DataRow(
        cells: [
          DataCell(Text(memory['before'])),
          DataCell(Text(memory['after'])),
          DataCell(
            IconButton(
              onPressed: () async {
                final id = memory['id'];

                await deleteMemoryFromLauncher(id);

                if (!mounted) return;

                setState(() {
                  memories.removeWhere((m) => m['id'] == id);
                });

                showSnackBar(context, "Deleted successfully", "");
              },

              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            ),
          ),
        ],
      );
    }).toList();
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _before,
                      decoration: InputDecoration(
                        hint: Text("Before"),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _after,
                      decoration: InputDecoration(
                        hint: Text("After"),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      addMemory();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(65, 50),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      "Add",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: DataTable(
                    columns: const <DataColumn>[
                      DataColumn(
                        label: Text(
                          'Before',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'After',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Action',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: memoryRows,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  addMemory() async {
    if (!checkValidMemoryInput()) {
      showSnackBar(context, "Invalid Input", "error");
      return;
    }

    final beforeText = _before.text;
    final afterText = _after.text;

    final id = await insertMemoryFromLauncher(beforeText, afterText);

    if (!mounted) return;

    setState(() {
      memories.insert(0, {'id': id, 'before': beforeText, 'after': afterText});
    });

    _before.clear();
    _after.clear();

    showSnackBar(context, "Added Successfully", "");
  }

  bool checkValidMemoryInput() {
    if (_after.text == "" || _before.text == "") {
      return false;
    } else {
      return true;
    }
  }
}
