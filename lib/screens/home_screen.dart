import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/lyric_line.dart';
import '../services/audd_service.dart';
import '../widgets/lyrics_box.dart';

enum _AppState { idle, recording, analyzing, showingLyrics }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioRecorder _recorder = AudioRecorder();

  _AppState _state = _AppState.idle;
  String? _statusMessage;

  String _title = '';
  String _artist = '';
  List<LyricLine> _lyrics = [];

  Timer? _lyricTimer;
  int _currentIndex = 0;
  DateTime? _lyricsStartedAt;

  // How long to record before sending the clip to AudD. AudD generally
  // needs a few seconds of clear audio to fingerprint a song reliably.
  static const Duration _recordDuration = Duration(seconds: 7);

  @override
  void dispose() {
    _lyricTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (_state == _AppState.recording || _state == _AppState.analyzing) return;

    _lyricTimer?.cancel();
    setState(() {
      _state = _AppState.recording;
      _statusMessage = null;
    });

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _state = _AppState.idle;
          _statusMessage = '마이크 권한이 필요합니다 (Microphone permission required)';
        });
        return;
      }

      // dart:io's system temp directory works fine on Android for a
      // short-lived scratch file — no extra path_provider dependency needed.
      final capturePath = '${Directory.systemTemp.path}/audd_capture.m4a';
      final existing = File(capturePath);
      if (await existing.exists()) {
        await existing.delete();
      }

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: capturePath,
      );

      await Future.delayed(_recordDuration);
      final stoppedPath = await _recorder.stop();

      if (!mounted) return;
      setState(() => _state = _AppState.analyzing);

      final file = File(stoppedPath ?? capturePath);
      final result = await AuddService.recognize(file);

      if (!mounted) return;
      setState(() {
        _title = result.title;
        _artist = result.artist;
        _lyrics = result.lyrics;
        _statusMessage = result.message;
        _state = _AppState.showingLyrics;
      });

      _startLyricSync();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _AppState.idle;
        _statusMessage = '오류가 발생했습니다 (Something went wrong)';
      });
    }
  }

  void _startLyricSync() {
    _lyricTimer?.cancel();
    _lyricsStartedAt = DateTime.now();
    _currentIndex = 0;

    if (_lyrics.isEmpty) return;

    _lyricTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final startedAt = _lyricsStartedAt;
      if (startedAt == null) return;

      final elapsed = DateTime.now().difference(startedAt);
      var newIndex = 0;
      for (var i = 0; i < _lyrics.length; i++) {
        if (_lyrics[i].time <= elapsed) {
          newIndex = i;
        } else {
          break;
        }
      }

      if (newIndex != _currentIndex) {
        setState(() => _currentIndex = newIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasLyrics = _lyrics.isNotEmpty;
    final currentLine = hasLyrics ? _lyrics[_currentIndex].text : '';
    final nextLine = (hasLyrics && _currentIndex + 1 < _lyrics.length)
        ? _lyrics[_currentIndex + 1].text
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('노래 가사 인식 · Song Lyrics'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              if (_state == _AppState.showingLyrics) ...[
                const SizedBox(height: 4),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _artist,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
              ],
              Expanded(
                child: Center(
                  child: _state == _AppState.showingLyrics
                      ? LyricsBox(currentLine: currentLine, nextLine: nextLine)
                      : _buildIdleContent(),
                ),
              ),
              if (_statusMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
                  ),
                ),
              ],
              _buildMicButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdleContent() {
    final String text;
    switch (_state) {
      case _AppState.recording:
        text = '듣는 중... 🎧\nListening...';
        break;
      case _AppState.analyzing:
        text = '분석 중...\nIdentifying song...';
        break;
      case _AppState.idle:
      case _AppState.showingLyrics:
        text = '마이크 버튼을 눌러 노래를 들어보세요\nTap the mic button to identify a song';
        break;
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
    );
  }

  Widget _buildMicButton() {
    final isBusy = _state == _AppState.recording || _state == _AppState.analyzing;
    return GestureDetector(
      onTap: isBusy ? null : _listen,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isBusy ? Colors.deepPurple.shade900 : Colors.deepPurple,
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isBusy ? Icons.graphic_eq : Icons.mic,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}
