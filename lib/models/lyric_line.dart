/// A single line of lyrics paired with the timestamp (relative to the
/// start of playback/recognition) at which it should appear on screen.
class LyricLine {
  final Duration time;
  final String text;

  const LyricLine({required this.time, required this.text});
}
