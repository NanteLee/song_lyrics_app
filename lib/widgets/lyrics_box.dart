import 'package:flutter/material.dart';

/// Large "subtitle" style box showing exactly two lyric lines at a time:
/// the current line (bright/bold) and the next upcoming line (dimmed).
class LyricsBox extends StatelessWidget {
  final String currentLine;
  final String nextLine;

  const LyricsBox({
    super.key,
    required this.currentLine,
    required this.nextLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentLine,
            textAlign: TextAlign.center,
            // Korean glyphs render via the system's CJK fallback font on
            // Android automatically — no extra font asset is required.
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            nextLine,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: Colors.white38,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
