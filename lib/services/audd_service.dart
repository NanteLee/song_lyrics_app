import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/lyric_line.dart';
import 'demo_lyrics.dart';
import 'lrc_parser.dart';

enum RecognitionStatus { success, demo, notFound }

/// Result of a recognition attempt. Always contains something displayable
/// (real data OR demo data) — this service never surfaces a raw exception
/// to the UI, per the "handle network errors gracefully" requirement.
class RecognitionResult {
  final RecognitionStatus status;
  final String title;
  final String artist;
  final List<LyricLine> lyrics;

  /// Optional small status/help text shown under the lyrics box
  /// (e.g. "no internet connection", "lyrics not available").
  final String? message;

  const RecognitionResult({
    required this.status,
    required this.title,
    required this.artist,
    required this.lyrics,
    this.message,
  });

  factory RecognitionResult.demo({String? message}) => RecognitionResult(
        status: RecognitionStatus.demo,
        title: DemoLyrics.title,
        artist: DemoLyrics.artist,
        lyrics: DemoLyrics.lines,
        message: message,
      );
}

/// Thin client for the AudD recognition API (https://audd.io).
///
/// Docs: https://docs.audd.io/
/// Endpoint: POST https://api.audd.io/ (multipart form: api_token, file, return)
class AuddService {
  static const String _endpoint = 'https://api.audd.io/';

  static Future<RecognitionResult> recognize(File audioFile) async {
    // No token configured -> skip network entirely, show demo lyrics.
    if (auddApiToken.trim().isEmpty) {
      return RecognitionResult.demo(
        message: 'AUDD_API_TOKEN이 설정되지 않았습니다 (No API token set) — 데모 가사 표시',
      );
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_endpoint))
        ..fields['api_token'] = auddApiToken
        // Ask AudD to include lyrics text when the underlying provider
        // has them. This may come back as plain text or as LRC-tagged
        // (synchronized) text depending on your plan — both are handled
        // below via LrcParser.
        ..fields['return'] = 'lyrics'
        ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        return RecognitionResult.demo(
          message: '서버 오류 (HTTP ${response.statusCode}) — 데모 가사 표시',
        );
      }

      final Map<String, dynamic> json = jsonDecode(response.body);

      if (json['status'] != 'success') {
        final err = json['error'];
        final errMsg = err is Map ? err['error_message'] : null;
        return RecognitionResult.demo(
          message: errMsg != null
              ? '인식 실패: $errMsg — 데모 가사 표시'
              : '인식에 실패했습니다 — 데모 가사 표시',
        );
      }

      final result = json['result'];
      if (result == null) {
        // Valid response, but no match found for this audio clip.
        return RecognitionResult(
          status: RecognitionStatus.notFound,
          title: '노래를 찾을 수 없습니다 (Song not recognized)',
          artist: '음악에 더 가까이 대고 다시 시도해 보세요',
          lyrics: DemoLyrics.lines,
          message: 'Try again closer to the music source',
        );
      }

      final title = _nonEmpty(result['title']) ?? 'Unknown title';
      final artist = _nonEmpty(result['artist']) ?? 'Unknown artist';
      final String? lyricsText = _nonEmpty(result['lyrics']);

      List<LyricLine> lines;
      String? message;

      if (lyricsText == null) {
        lines = DemoLyrics.lines;
        message = '이 곡의 가사를 찾을 수 없습니다 (Lyrics not available for this song)';
      } else if (LrcParser.looksLikeLrc(lyricsText)) {
        lines = LrcParser.parse(lyricsText);
      } else {
        lines = LrcParser.fromPlainText(lyricsText);
        message = '동기화된 가사가 없어 자동 진행으로 표시합니다 (No timed lyrics — auto-advancing)';
      }

      return RecognitionResult(
        status: RecognitionStatus.success,
        title: title,
        artist: artist,
        lyrics: lines,
        message: message,
      );
    } on TimeoutException {
      return RecognitionResult.demo(message: '네트워크 시간 초과 (Network timeout) — 데모 가사 표시');
    } on SocketException {
      return RecognitionResult.demo(
        message: '인터넷 연결을 확인하세요 (No internet connection) — 데모 가사 표시',
      );
    } catch (e) {
      return RecognitionResult.demo(message: '오류가 발생했습니다 (Unexpected error) — 데모 가사 표시');
    }
  }

  static String? _nonEmpty(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }
}
