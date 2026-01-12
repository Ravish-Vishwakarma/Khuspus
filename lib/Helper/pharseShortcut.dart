import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class ParsedShortcut {
  final PhysicalKeyboardKey key;
  final List<HotKeyModifier> modifiers;

  ParsedShortcut({required this.key, required this.modifiers});
}

List<String> normalizeShortcut(String shortcut) {
  return shortcut
      .split('+')
      .map((p) => p.trim().toUpperCase())
      .where((p) => p.isNotEmpty)
      .toList();
}

HotKeyModifier? parseModifier(String part) {
  switch (part) {
    case 'SHIFT':
      return HotKeyModifier.shift;

    case 'CTRL':
    case 'CONTROL':
      return HotKeyModifier.control;

    case 'ALT':
      return HotKeyModifier.alt;

    case 'META':
    case 'CMD':
    case 'WIN':
      return HotKeyModifier.meta;

    default:
      return null;
  }
}

List<HotKeyModifier> extractModifiers(List<String> parts) {
  final modifiers = <HotKeyModifier>{};

  for (final part in parts) {
    final modifier = parseModifier(part);
    if (modifier != null) {
      modifiers.add(modifier);
    }
  }

  return modifiers.toList();
}

final Map<String, PhysicalKeyboardKey> specialKeyMap = {
  // Function keys
  'F1': PhysicalKeyboardKey.f1,
  'F2': PhysicalKeyboardKey.f2,
  'F3': PhysicalKeyboardKey.f3,
  'F4': PhysicalKeyboardKey.f4,
  'F5': PhysicalKeyboardKey.f5,
  'F6': PhysicalKeyboardKey.f6,
  'F7': PhysicalKeyboardKey.f7,
  'F8': PhysicalKeyboardKey.f8,
  'F9': PhysicalKeyboardKey.f9,
  'F10': PhysicalKeyboardKey.f10,
  'F11': PhysicalKeyboardKey.f11,
  'F12': PhysicalKeyboardKey.f12,
  'F13': PhysicalKeyboardKey.f13,
  'F14': PhysicalKeyboardKey.f14,
  'F15': PhysicalKeyboardKey.f15,
  'F16': PhysicalKeyboardKey.f16,
  'F17': PhysicalKeyboardKey.f17,
  'F18': PhysicalKeyboardKey.f18,
  'F19': PhysicalKeyboardKey.f19,
  'F20': PhysicalKeyboardKey.f20,
  'F21': PhysicalKeyboardKey.f21,
  'F22': PhysicalKeyboardKey.f22,
  'F23': PhysicalKeyboardKey.f23,
  'F24': PhysicalKeyboardKey.f24,

  // Numpad
  'NUMPAD ADD': PhysicalKeyboardKey.numpadAdd,
  'NUMPAD SUBTRACT': PhysicalKeyboardKey.numpadSubtract,
  'NUMPAD MULTIPLY': PhysicalKeyboardKey.numpadMultiply,
  'NUMPAD DIVIDE': PhysicalKeyboardKey.numpadDivide,
  'NUMPAD ENTER': PhysicalKeyboardKey.numpadEnter,

  'NUMPAD 0': PhysicalKeyboardKey.numpad0,
  'NUMPAD 1': PhysicalKeyboardKey.numpad1,
  'NUMPAD 2': PhysicalKeyboardKey.numpad2,
  'NUMPAD 3': PhysicalKeyboardKey.numpad3,
  'NUMPAD 4': PhysicalKeyboardKey.numpad4,
  'NUMPAD 5': PhysicalKeyboardKey.numpad5,
  'NUMPAD 6': PhysicalKeyboardKey.numpad6,
  'NUMPAD 7': PhysicalKeyboardKey.numpad7,
  'NUMPAD 8': PhysicalKeyboardKey.numpad8,
  'NUMPAD 9': PhysicalKeyboardKey.numpad9,
};

final Map<String, PhysicalKeyboardKey> letterKeyMap = {
  'A': PhysicalKeyboardKey.keyA,
  'B': PhysicalKeyboardKey.keyB,
  'C': PhysicalKeyboardKey.keyC,
  'D': PhysicalKeyboardKey.keyD,
  'E': PhysicalKeyboardKey.keyE,
  'F': PhysicalKeyboardKey.keyF,
  'G': PhysicalKeyboardKey.keyG,
  'H': PhysicalKeyboardKey.keyH,
  'I': PhysicalKeyboardKey.keyI,
  'J': PhysicalKeyboardKey.keyJ,
  'K': PhysicalKeyboardKey.keyK,
  'L': PhysicalKeyboardKey.keyL,
  'M': PhysicalKeyboardKey.keyM,
  'N': PhysicalKeyboardKey.keyN,
  'O': PhysicalKeyboardKey.keyO,
  'P': PhysicalKeyboardKey.keyP,
  'Q': PhysicalKeyboardKey.keyQ,
  'R': PhysicalKeyboardKey.keyR,
  'S': PhysicalKeyboardKey.keyS,
  'T': PhysicalKeyboardKey.keyT,
  'U': PhysicalKeyboardKey.keyU,
  'V': PhysicalKeyboardKey.keyV,
  'W': PhysicalKeyboardKey.keyW,
  'X': PhysicalKeyboardKey.keyX,
  'Y': PhysicalKeyboardKey.keyY,
  'Z': PhysicalKeyboardKey.keyZ,
};

PhysicalKeyboardKey? resolveKey(String part) {
  // 1. Function keys, numpad, etc.
  final special = specialKeyMap[part];
  if (special != null) return special;

  // 2. Letters A–Z
  final letter = letterKeyMap[part];
  if (letter != null) return letter;

  return null;
}

PhysicalKeyboardKey extractMainKey(List<String> parts) {
  PhysicalKeyboardKey? foundKey;

  for (final part in parts) {
    if (parseModifier(part) != null) continue;

    final key = resolveKey(part);
    if (key == null) {
      throw Exception('Unsupported key: $part');
    }

    if (foundKey != null) {
      throw Exception('Multiple keys found in shortcut');
    }

    foundKey = key;
  }

  if (foundKey == null) {
    throw Exception('No key found in shortcut');
  }

  return foundKey;
}

HotKey hotKeyFromString(String shortcut) {
  final parts = shortcut.split('+').map((e) => e.trim().toUpperCase()).toList();

  final modifiers = <HotKeyModifier>[];

  for (final part in parts) {
    final modifier = parseModifier(part);
    if (modifier != null) {
      modifiers.add(modifier);
    }
  }

  final key = extractMainKey(parts);

  return HotKey(key: key, modifiers: modifiers, scope: HotKeyScope.system);
}

class ShortcutValidationResult {
  final bool isValid;
  final String? reason;

  const ShortcutValidationResult.valid() : isValid = true, reason = null;

  const ShortcutValidationResult.invalid(this.reason) : isValid = false;
}

final List<Set<String>> forbiddenCombos = [
  {'CTRL', 'ALT', 'DELETE'},
  {'CTRL', 'SHIFT', 'ESC'},
  {'META', 'L'}, // Windows lock
  {'META', 'D'}, // Show desktop
];

ShortcutValidationResult validateShortcut(String shortcut) {
  final parts = normalizeShortcut(shortcut);

  // 1. Must contain at least one modifier
  final modifiers = extractModifiers(parts);
  if (modifiers.isEmpty) {
    return const ShortcutValidationResult.invalid(
      'Shortcut must include at least one modifier key',
    );
  }

  // 2. Must contain exactly one main key
  try {
    extractMainKey(parts);
  } catch (e) {
    return ShortcutValidationResult.invalid(e.toString());
  }

  // 3. Check forbidden system shortcuts
  final partSet = parts.toSet();

  for (final forbidden in forbiddenCombos) {
    if (forbidden.every(partSet.contains)) {
      return ShortcutValidationResult.invalid(
        'This shortcut is reserved by the system',
      );
    }
  }

  return const ShortcutValidationResult.valid();
}
