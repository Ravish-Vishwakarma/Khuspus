import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khuspus/Helper/sendAIRequest.dart';
import 'package:khuspus/db/queries/setting_queries.dart';
import 'package:khuspus/db/queries/transcription_queries.dart';
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

class _LauncherScreenState extends State<LauncherScreen> with WindowListener {
  @override
  void initState() {
    super.initState();
    WindowManagerPlus.current.addListener(this);
  }

  @override
  void dispose() {
    WindowManagerPlus.current.removeListener(this);
    super.dispose();
  }

  @override
  Future<dynamic> onEventFromWindow(
    String eventName,
    int fromWindowId,
    dynamic arguments,
  ) async {
    if (eventName == "db_getSetting") {
      final key = arguments["key"];
      return await getSetting(key);
    }

    if (eventName == "db_setSetting") {
      final key = arguments["key"];
      final value = arguments["value"];
      return await setSetting(key, value);
    }

    return null;
  }

  // ---------------------------------------- VARAIBLES ---------------------------------------- //
  bool isVoiceMode = false;
  bool isProcessing = false;
  bool isPolishing = false;
  late int rowID;
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  // ---------------------------------------- STOPWATCH ---------------------------------------- //
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

  // ---------------------------------------- KEYBOARD ---------------------------------------- //
  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
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
    }
  }

  // ---------------------------------------- FORMATTING ---------------------------------------- //
  int wordCount(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  String extractWhisperText(String whisperOutput) {
    return whisperOutput
        .replaceAll(RegExp(r'\[.*?\]'), '')
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

  // ---------------------------------------- POLISHING USING AI ---------------------------------------- //
  Future<void> _handlePolish() async {
    if (textController.text.trim().isEmpty) return;

    setState(() {
      isPolishing = true;
    });

    // Simulate AI polishing
    var aiResponse = await sendAIRequest(textController.text);

    if (mounted) {
      setState(() {
        textController.text = aiResponse;
        isPolishing = false;
      });
    }

    await updatePolishedTranscript(id: rowID, polishedText: aiResponse);

    var oldAICount = await getSetting("aiCorrections");
    Clipboard.setData(ClipboardData(text: aiResponse));
    await setSetting(
      "aiCorrections",
      "${int.parse(oldAICount.toString()) + 1}",
    );
  }

  // ---------------------------------------- RECORDING ---------------------------------------- //
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

  // ------------------------------ TRANSCRIPTION ------------------------------ //
  Future<void> runWhisper(file) async {
    final result = await Process.run('whisper\\whisper-cli.exe', [
      '-m',
      // 'whisper\\model\\ggml-small.en.bin',
      'whisper\\model\\small.bin',
      '-f',
      '$file',
    ]);

    String cleanedTranscription = extractWhisperText(result.stdout);
    setState(() {
      isProcessing = false;
      isPolishing = false;
      textController.text = cleanedTranscription;
    });
    print("$cleanedTranscription");
    rowID = await insertTranscript(
      originalText: cleanedTranscription,
      polishedText: "empty",
      audioPath: file,
    );

    var oldWordCount = await getSetting("wordsProcessed");

    Clipboard.setData(ClipboardData(text: cleanedTranscription));
    await setSetting(
      "wordsProcessed",
      "${int.parse(oldWordCount.toString()) + wordCount(cleanedTranscription)}",
    );
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

  // ------------------------------ UI WIDGETS ------------------------------ //
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
            const SizedBox(width: 8),
            if (textController.text.isNotEmpty && !isProcessing && !isVoiceMode)
              _buildIconButton(Icons.auto_fix_high, _handlePolish),
            // const SizedBox(width: 8),
          ],
        ),
        Expanded(
          child: Container(
            height: 27,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) {
                WindowManagerPlus.current.startDragging();
              },
            ),
          ),
        ),
        _buildModeButton(),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(right: 0),
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
