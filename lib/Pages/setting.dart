import 'dart:io';

import 'package:flutter/material.dart';
import 'package:khuspus/Helper/pharseShortcut.dart';
import 'package:khuspus/Widgets/keyRecorder.dart';
import 'package:khuspus/Widgets/modelDropdown.dart';
import 'package:khuspus/Widgets/snackbar.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
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

  String ORIGINAL_PROMPT =
      '''You are an expert editor. Polish the following text to be clear, concise, and grammatically perfect.
Do not add any commentary, just return the polished text.{{memory}}

Original text: "{{transcription}}"

If the user's text contains the keyword 'SYSTEM', treat the words following 'SYSTEM' as a direct command and perform that action on the text instead of polishing.
''';

  TextEditingController _prompt = TextEditingController();
  String shortcutKey = "Something Went Wrong";
  bool isRecordingKeys = false;
  bool autoPolish = false;

  Future<void> getAutoRefine() async {
    final value = await getSettingFromLauncher("autoRefine");
    if (value == "true") {
      setState(() {
        autoPolish = true;
      });
    } else {
      autoPolish = false;
    }
  }

  Future<void> setAutoRefineValue(bool val) async {
    setState(() {
      autoPolish = val;
    });
    await setSettingFromLauncher("autoRefine", "$val");
  }

  Future<List<String>> getOllamaModelNames() async {
    try {
      final result = await Process.run('ollama', ['list']);

      if (result.exitCode != 0) {
        print('Error: ${result.stderr}');
        return [];
      }

      final lines = result.stdout
          .toString()
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      if (lines.isEmpty) return [];

      // Skip the header line
      final dataLines = lines.skip(1);

      final modelNames = <String>[];
      for (final line in dataLines) {
        final parts = line.split(RegExp(r'\s{2,}')); // split by multiple spaces
        if (parts.isNotEmpty) {
          modelNames.add(parts[0]); // only take the name
        }
      }
      print(modelNames);
      return modelNames;
    } catch (e) {
      print('Exception: $e');
      return [];
    }
  }

  Future<void> _loadPrompt() async {
    final value = await getSettingFromLauncher('polish_prompt');

    if (!mounted) return;

    setState(() {
      _prompt.text = value ?? '';
    });
  }

  Future<void> _loadShortcut() async {
    final value = await getSettingFromLauncher('launcherShortcut');

    if (!mounted) return;

    setState(() {
      shortcutKey = value!;
    });
  }

  _startup() async {
    await _loadPrompt();
    await _loadShortcut();
    await getOllamaModelNames();
    await getAutoRefine();
  }

  @override
  void initState() {
    super.initState();
    _startup();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("AI Model (Ollama): ", style: TextStyle(fontSize: 14)),
              SizedBox(width: 200, height: 40, child: ModelDropdown()),
            ],
          ),
          SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Launcher Shortcut (Require App Restart To Use New Shortcut): ",
              ),
              Row(
                children: [
                  if (isRecordingKeys)
                    SizedBox(
                      width: 250,
                      child: ShortcutRecorder(
                        onSave: (shortcut) async {
                          print("Shortcut saved: $shortcut");
                          final result = validateShortcut(shortcut);
                          if (!result.isValid) {
                            print(result.reason);
                            showSnackBar(
                              context,
                              "Invalid Combination",
                              "error",
                            );
                            isRecordingKeys = false;
                            return;
                          } else {
                            await setSettingFromLauncher(
                              "launcherShortcut",
                              shortcut,
                            );
                            setState(() {
                              isRecordingKeys = false;
                              shortcutKey = shortcut;
                            });
                          }
                        },
                      ),
                    )
                  else
                    Text(shortcutKey),
                  SizedBox(width: 5),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        isRecordingKeys = !isRecordingKeys;
                      });
                    },
                    iconSize: 18,
                    icon: Icon(
                      isRecordingKeys ? Icons.close : Icons.edit_outlined,
                    ),
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Auto Polish (AI)"),
              Switch(
                value: autoPolish,
                onChanged: (value) {
                  setAutoRefineValue(value);
                  print(value);
                },
              ),
            ],
          ),
          SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("AI Polishing Prompt"),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _prompt.text = ORIGINAL_PROMPT;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.replay_rounded),
                            SizedBox(width: 4),
                            Text("Reset"),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await setSettingFromLauncher(
                          "polish_prompt",
                          _prompt.text,
                        );
                        showSnackBar(context, "Saved Successfully", "");
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(Icons.save_rounded),
                            SizedBox(width: 4),
                            Text("Save"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          TextField(
            controller: _prompt,
            minLines: 1, // initial height
            maxLines: null,
            style: TextStyle(
              fontSize: 15, // set the text size here
              color: Colors.black, // optional text color
            ),
            decoration: InputDecoration(
              labelText: "Prompt",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(height: 5),
          RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey, fontSize: 10),
              children: const [
                TextSpan(text: 'Use '),
                TextSpan(
                  text: '{{memory}}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' to insert your custom spelling corrections and ',
                ),
                TextSpan(
                  text: '{{transcription}}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' to insert the text to be polished.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
