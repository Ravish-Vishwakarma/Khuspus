// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khuspus/Widgets/snackbar.dart';
import 'package:open_filex/open_filex.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  TextEditingController _nameController = TextEditingController();
  var wordProcessd, aiCorrections, userName;

  Future<dynamic> getSettingFromLauncher(String key) async {
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();

    // Find launcher window by title
    for (final id in windowIds) {
      final win = WindowManagerPlus.fromWindowId(id);
      final title = await win.getTitle();

      if (title == 'Launcher Window') {
        return await WindowManagerPlus.current.invokeMethodToWindow(
          id,
          "db_getSetting",
          {"key": key},
        );
      }
    }

    throw Exception("Launcher window not found");
  }

  Future<dynamic> setSettingFromLauncher(String key, String val) async {
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();

    // Find launcher window by title
    for (final id in windowIds) {
      final win = WindowManagerPlus.fromWindowId(id);
      final title = await win.getTitle();

      if (title == 'Launcher Window') {
        return await WindowManagerPlus.current.invokeMethodToWindow(
          id,
          "db_setSetting",
          {"key": key, "value": val},
        );
      }
    }

    throw Exception("Launcher window not found");
  }

  Future<dynamic> deleteTranscriptsFromLauncher(int tid, String path) async {
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();

    // Find launcher window by title
    for (final id in windowIds) {
      final win = WindowManagerPlus.fromWindowId(id);
      final title = await win.getTitle();

      if (title == 'Launcher Window') {
        return await WindowManagerPlus.current.invokeMethodToWindow(
          id,
          "db_deleteTranscripts",
          {"id": tid, "path": path},
        );
      }
    }

    throw Exception("Launcher window not found");
  }

  Future<List<Map<String, dynamic>>> loadTranscriptsFromLauncher() async {
    final windowIds = await WindowManagerPlus.getAllWindowManagerIds();

    for (final id in windowIds) {
      final win = WindowManagerPlus.fromWindowId(id);
      final title = await win.getTitle();

      if (title == 'Launcher Window') {
        final result = await WindowManagerPlus.current.invokeMethodToWindow(
          id,
          "db_loadTranscripts",
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

  Future<void> getMetaData() async {
    final word = await getSettingFromLauncher("wordsProcessed");
    final ai = await getSettingFromLauncher("aiCorrections");
    final name = await getSettingFromLauncher("userName");
    setState(() {
      wordProcessd = word!;
      aiCorrections = ai!;
      userName = name!;
    });
  }

  var isEditing = false;
  List<Map<String, dynamic>> transcripts = [];

  Future<void> _loadTranscripts() async {
    final data = await loadTranscriptsFromLauncher();

    if (!mounted) return;

    setState(() {
      transcripts = data;
    });
  }

  _startup() async {
    await getMetaData();
    await _loadTranscripts();
  }

  @override
  void initState() {
    super.initState();
    _startup();
  }

  @override
  Widget build(BuildContext context) {
    late List<DataRow> transcriptsRows = transcripts.map((trans) {
      return DataRow(
        cells: [
          DataCell(
            IconButton(
              onPressed: () async {
                await OpenFilex.open(trans['audioPath']);
              },
              icon: Icon(Icons.play_arrow_rounded),
            ),
          ),
          DataCell(
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: trans['originalText']));
                showSnackBar(context, "Copied", "basic");
              },
              child: Text(
                trans['originalText'],
                // softWrap: true,
                // maxLines: null,
                // overflow: TextOverflow.visible,
              ),
            ),
          ),
          DataCell(
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: trans['polishedText']));
                showSnackBar(context, "Copied", "basic");
              },
              child: Text(
                trans['polishedText'],
                // softWrap: true,
                // maxLines: null,
                // overflow: TextOverflow.visible,
              ),
            ),
          ),
          DataCell(
            IconButton(
              onPressed: () async {
                await deleteTranscriptsFromLauncher(
                  trans['id'],
                  trans['audioPath'],
                );
                setState(() {
                  transcripts.removeWhere(
                    (element) => element['id'] == trans['id'],
                  );
                });
              },
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red),
            ),
          ),
        ],
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey, width: 0.7),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      isEditing
                          ? SizedBox(
                              width: 240,
                              height: 30,
                              child: TextField(
                                controller: _nameController,
                                style: TextStyle(fontSize: 14), // small text
                                textAlign: TextAlign.left,
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.all(
                                    4,
                                  ), // shrink internal padding
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      6,
                                    ), // optional rounding
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              "Hi, $userName",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                            ),
                      SizedBox(width: 5),
                      IconButton(
                        icon: Icon(
                          isEditing ? Icons.save : Icons.edit_outlined,
                        ),
                        iconSize: 18,
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                        onPressed: () async {
                          setState(() {
                            isEditing = !isEditing;
                            isEditing
                                ? _nameController.text = userName
                                : userName = _nameController.text;
                          });
                          await setSettingFromLauncher(
                            "userName",
                            _nameController.text,
                          );

                          // !isEditing ? await setUsername() : null;
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Word processes \n',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: wordProcessd,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        textAlign: TextAlign.right,
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <TextSpan>[
                            TextSpan(
                              text: 'AI corrections\n',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: aiCorrections,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey, width: 0.7),
            ),
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(
                  label: Text(
                    'Voice',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Original',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'AI Result',
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
              rows: transcriptsRows,
            ),
          ),
        ),
      ],
    );
  }
}
