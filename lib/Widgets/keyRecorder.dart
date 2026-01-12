import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShortcutRecorder extends StatefulWidget {
  final ValueChanged<String> onSave;

  const ShortcutRecorder({super.key, required this.onSave});

  @override
  State<ShortcutRecorder> createState() => _ShortcutRecorderState();
}

class _ShortcutRecorderState extends State<ShortcutRecorder> {
  Set<LogicalKeyboardKey> _pressedKeys = {};
  String _capturedShortcut = '';
  bool _isRecording = true;

  bool _isModifier(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
  }

  String _formatKeys(Set<LogicalKeyboardKey> keys) {
    final parts = <String>[];

    if (keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight)) {
      parts.add('Shift');
    }
    if (keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight)) {
      parts.add('Ctrl');
    }
    if (keys.contains(LogicalKeyboardKey.altLeft) ||
        keys.contains(LogicalKeyboardKey.altRight)) {
      parts.add('Alt');
    }
    if (keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight)) {
      parts.add('Meta');
    }

    // Add first non-modifier key
    for (final key in keys) {
      if (!_isModifier(key)) {
        parts.add(
          key.keyLabel.isNotEmpty ? key.keyLabel : key.debugName ?? 'Unknown',
        );
        break;
      }
    }

    return parts.join('+');
  }

  void _onKey(RawKeyEvent event) {
    if (!_isRecording) return; // Ignore further key events after capture

    if (event is RawKeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      final combo = _formatKeys(_pressedKeys);
      if (combo.isNotEmpty) {
        setState(() {
          _capturedShortcut = combo; // Capture the combination
        });
      }
    }
  }

  void _saveShortcut() {
    if (_capturedShortcut.isNotEmpty) {
      widget.onSave(_capturedShortcut);
      setState(() {
        _isRecording = true;
      });
    }
  }

  void _resetShortcut() {
    setState(() {
      _capturedShortcut = '';
      _pressedKeys.clear();
      _isRecording = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: _onKey,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _capturedShortcut.isEmpty
                    ? 'Press shortcut...'
                    : _capturedShortcut,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.red),
            tooltip: 'Reset',
            onPressed: _resetShortcut,
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Colors.green),
            tooltip: 'Save',
            onPressed: _saveShortcut,
          ),
        ],
      ),
    );
  }
}
