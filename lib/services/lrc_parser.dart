import '../models/lyric_line.dart';

/// Parses lyrics in the standard LRC format, e.g.:
///
///   [00:12.34]안녕하세요 반가워요
///   [00:15.10]Hello, nice to meet you
///
/// Depending on your AudD plan and the underlying lyrics provider,
/// the "lyrics" field returned by the API may or may not contain
/// these [mm:ss.xx] timestamp tags (true synchronized lyrics).
///
/// - If tags are present -> use [parse] for real synchronized lyrics.
/// - If the text is plain (no tags) -> use [fromPlainText], which
///   assigns each line an even, fixed interval so the UI can still
///   auto-advance in a karaoke-like way.
class LrcParser {
  static final RegExp _tagPattern =
      RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{1,2}))?\]');

  /// Quick check used by AuddService to decide which path to take.
  static bool looksLikeLrc(String text) => _tagPattern.hasMatch(text);

  static List<LyricLine> parse(String lrc) {
    final lines = <LyricLine>[];

    for (final rawLine in lrc.split('\n')) {
      final matches = _tagPattern.allMatches(rawLine).toList();
      if (matches.isEmpty) continue;

      final content = rawLine.replaceAll(_tagPattern, '').trim();
      if (content.isEmpty) continue;

      // A single line can carry multiple timestamps (rare, but valid LRC).
      for (final m in matches) {
        final minutes = int.parse(m.group(1)!);
        final seconds = int.parse(m.group(2)!);
        final fraction = m.group(3);
        final millis = fraction == null
            ? 0
            : int.parse(fraction.padRight(3, '0').substring(0, 3));

        lines.add(
          LyricLine(
            time: Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
            text: content,
          ),
        );
      }
    }

    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  /// Fallback for plain (un-timed) lyrics text: gives each non-empty
  /// line a fixed on-screen interval.
  static List<LyricLine> fromPlainText(
    String text, {
    Duration interval = const Duration(seconds: 4),
  }) {
    final rawLines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final result = <LyricLine>[];
    for (var i = 0; i < rawLines.length; i++) {
      result.add(LyricLine(time: interval * i, text: rawLines[i]));
    }
    return result;
  }
}
