// ============================================================================
// AUDD API TOKEN — PLACE YOUR TOKEN HERE
// ============================================================================
//
// Option A (quick start): leave the defaultValue below as-is. It is already
// set to the token you provided:
//     738e05089ea89479048e178759ac29d8
//
// Option B (recommended for real use / before sharing your source code):
// don't hardcode a real token in source. Instead pass it at build/run time:
//
//     flutter run --dart-define=AUDD_API_TOKEN=your_token_here
//     flutter build apk --dart-define=AUDD_API_TOKEN=your_token_here
//
// Get a free AudD token at: https://dashboard.audd.io/
//
// IMPORTANT (per app requirements): if this value is empty (either because
// you cleared the defaultValue and didn't pass --dart-define), the app will
// NOT show a network/API error. Instead it automatically falls back to demo
// lyrics so the UI is always demonstrable. See lib/services/audd_service.dart.
// ============================================================================
const String auddApiToken = String.fromEnvironment(
  'AUDD_API_TOKEN',
  defaultValue: '738e05089ea89479048e178759ac29d8',
);
