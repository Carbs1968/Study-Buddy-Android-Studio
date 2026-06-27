// Helper to format recording file names while preserving readable class/topic text.
String fileNameFormatted({
  required String className,
  required String topic,
  required DateTime when,
}) {
  String clean(String s) {
    return s
        .trim()
        .replaceAll(RegExp(r'[\/\\:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
  final c = clean(className);
  final t = clean(topic);
  final y = when.year.toString().padLeft(4, '0');
  final m = when.month.toString().padLeft(2, '0');
  final d = when.day.toString().padLeft(2, '0');
  final hh = when.hour.toString().padLeft(2, '0');
  final mm = when.minute.toString().padLeft(2, '0');
  final ss = when.second.toString().padLeft(2, '0');
  return '$c - $t - $y-$m-${d}_$hh-$mm-$ss.m4a';
}


String formatDuration(Duration d) {
  final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hh = d.inHours > 0 ? '${d.inHours}:' : '';
  return '$hh$mm:$ss';
}
