import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

class LauncherWindow extends StatefulWidget {
  const LauncherWindow({super.key});

  @override
  State<LauncherWindow> createState() => _LauncherWindowState();
}

class _LauncherWindowState extends State<LauncherWindow> {
  @override
  Widget build(BuildContext context) {
    return LauncherScreen();
  }
}

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  bool isVoiceMode = false;
  bool isProcessing = false;
  bool isPolishing = false;
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  void _stopwatchStart() {
    _stopwatch.start();
    _timer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      setState(() {});
    });
  }

  void _stopwatchStop() {
    _stopwatch.stop();
    _timer?.cancel();
  }

  void _stopwatchReset() {
    _stopwatch.reset();
    setState(() {});
  }

  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      setState(() {
        isVoiceMode = !isVoiceMode;
        if (isVoiceMode) {
          textController.clear();
          // Start recording
          startRecording();
        } else {
          // Stop recording
          stopRecording();
          isProcessing = true;
        }
      });
    }
  }

  String extractWhisperText(String whisperOutput) {
    return whisperOutput
        // remove timestamps
        .replaceAll(RegExp(r'\[.*?\]'), '')
        // remove extra spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _formattedTime() {
    final elapsed = _stopwatch.elapsed;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds = (elapsed.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');

    return "$minutes:$seconds.$milliseconds";
  }

  Future<void> _handlePolish() async {
    if (textController.text.trim().isEmpty) return;

    setState(() {
      isPolishing = true;
    });

    // Simulate AI polishing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        textController.text = "${textController.text} (polished)";
        isPolishing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 0, 0, 0),
      body: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: handleKeyEvent,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildMainContent(),
                  ),
                ),
              ),

              // Bottom Controls
              const SizedBox(height: 8),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (isProcessing || isPolishing) {
      return _buildLoadingState();
    } else if (isVoiceMode) {
      return _buildVoiceVisualizer();
    } else {
      return _buildTextInput();
    }
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.green.withOpacity(0.8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          isPolishing ? 'Polishing with AI...' : 'Whisper is thinking...',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: textController,
      focusNode: focusNode,
      maxLines: null,
      autofocus: true,
      style: const TextStyle(color: Color(0xFFF4F4F5), fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Press \'Tab\' To Record',
        hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildVoiceVisualizer() {
    return Row(
      children: [
        Icon(Icons.mic, color: Colors.green),
        Text("${_formattedTime()}", style: TextStyle(color: Colors.white)),
      ],
    );
  }

  // ------------------------------ AUDIO ------------------------------ //
  String? currentRecordingPath;
  final recorder = AudioRecorder();

  Future<void> startRecording() async {
    final audioDir = Directory('audio');
    if (!audioDir.existsSync()) audioDir.createSync();

    int i = 1;
    String filePath;
    do {
      filePath = '${audioDir.path}\\audio$i.wav';
      i++;
    } while (File(filePath).existsSync());

    currentRecordingPath = filePath;

    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: filePath,
    );
    print('Recording started...');
    setState(() {
      isVoiceMode = true;
    });

    _stopwatchReset();
    _stopwatchStart();
  }

  Future<String?> stopRecording() async {
    final recordedPath = await recorder.stop();
    // recorder.dispose();
    print('Recording stopped: $recordedPath');
    setState(() {
      isVoiceMode = false;
      isProcessing = true;
      isPolishing = false;
    });
    runWhisper(recordedPath);
    _stopwatchStop();
    return recordedPath;
  }

  Future<void> runWhisper(file) async {
    final result = await Process.run('whisper\\whisper-cli.exe', [
      '-m',
      'whisper\\model\\ggml-small.en.bin',
      '-f',
      '$file',
    ]);

    String cleanedTranscription = extractWhisperText(result.stdout);
    setState(() {
      isProcessing = false;
      isPolishing = false;
      textController.text = cleanedTranscription;
    });
    print(result.stdout);
    print("Done");
  }

  // ------------------------------ AUDIO END ------------------------------ //

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildIconButton(Icons.history, () async {
              await WindowManagerPlus.current.setSize(
                const Size(800, 500),
                animate: true,
              );
            }),

            if (textController.text.isNotEmpty && !isProcessing && !isVoiceMode)
              _buildIconButton(Icons.auto_fix_high, _handlePolish),
            const SizedBox(width: 8),
          ],
        ),
        _buildModeButton(),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF3F3F46)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 14, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton() {
    return Material(
      color: isVoiceMode ? Colors.green.shade500 : const Color(0xFF27272A),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          setState(() {
            isVoiceMode = !isVoiceMode;
            if (isVoiceMode) {
              textController.clear();
              startRecording();
            } else {
              stopRecording();
              isProcessing = true;
            }
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            border: isVoiceMode
                ? null
                : Border.all(color: const Color(0xFF3F3F46)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isVoiceMode ? Icons.arrow_upward : Icons.mic,
            size: 16,
            color: isVoiceMode ? Colors.black : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
