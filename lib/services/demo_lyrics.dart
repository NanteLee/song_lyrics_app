import '../models/lyric_line.dart';

/// Demo content shown instead of an error whenever:
///  - AUDD_API_TOKEN is not configured, or
///  - a network/API error occurs, or
///  - a song is identified but no lyrics are available.
///
/// This keeps the app fully usable and demo-able with zero setup,
/// per the "no error screens" requirement.
class DemoLyrics {
  static const String title = '데모 노래 (Demo Song)';
  static const String artist = '샘플 아티스트 (Sample Artist)';

  static const List<LyricLine> lines = [
    LyricLine(time: Duration(seconds: 0), text: '이것은 데모 가사입니다'),
    LyricLine(time: Duration(seconds: 4), text: 'This is a demo lyric line'),
    LyricLine(time: Duration(seconds: 8), text: 'API 토큰을 설정하면'),
    LyricLine(time: Duration(seconds: 12), text: 'real songs will be recognized'),
    LyricLine(time: Duration(seconds: 16), text: '실제 노래 가사가 화면에 표시됩니다'),
    LyricLine(time: Duration(seconds: 20), text: 'Set AUDD_API_TOKEN in lib/config.dart'),
    LyricLine(time: Duration(seconds: 24), text: '마이크 버튼을 눌러 들어보세요'),
    LyricLine(time: Duration(seconds: 28), text: 'Tap the mic button to try listening'),
  ];
}
