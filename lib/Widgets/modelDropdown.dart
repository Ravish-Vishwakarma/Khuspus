// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class ModelDropdown extends StatefulWidget {
  const ModelDropdown({super.key});

  @override
  State<ModelDropdown> createState() => _ModelDropdownState();
}

class _ModelDropdownState extends State<ModelDropdown> {
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

  String? selectedModel;
  List<String> modelNames = [];
  bool isLoading = true;
  String? savedModelName;

  Future<void> _loadShortcut() async {
    final value = await getSettingFromLauncher('aiModel');

    if (!mounted) return;

    setState(() {
      savedModelName = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadModels();
    _loadShortcut();
  }

  Future<List<String>> getOllamaModelNames() async {
    try {
      final result = await Process.run('ollama', ['list']);

      if (result.exitCode != 0) {
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
      return modelNames;
    } catch (e) {
      return [];
    }
  }

  Future<void> _loadModels() async {
    final models = await getOllamaModelNames();
    if (!mounted) return;

    setState(() {
      modelNames = models;
      isLoading = false;
      if (models.isNotEmpty && savedModelName != "none") {
        selectedModel = savedModelName;
      } else {
        selectedModel = models.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    return DropdownButtonFormField<String>(
      value: selectedModel,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 0.8, color: Colors.grey),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
      dropdownColor: Colors.white,
      items: modelNames
          .map((model) => DropdownMenuItem(value: model, child: Text(model)))
          .toList(),
      onChanged: (value) async {
        setState(() {
          selectedModel = value!;
        });
        await setSettingFromLauncher("aiModel", value!);
      },
    );
  }
}
