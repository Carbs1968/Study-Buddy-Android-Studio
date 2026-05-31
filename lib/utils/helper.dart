// Helper to format recording file names while preserving readable class/topic text.
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'app_logger.dart';

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

// Helper to upload to Firebase Storage with retry on object-not-found, unauthorized, or canceled
Future<TaskSnapshot> _uploadToStorageWithRetry(Reference ref, File file,
    {int maxRetries = 2}) async {
  int attempt = 0;
  while (true) {
    attempt++;
    try {
      return await ref.putFile(
        file,
        SettableMetadata(contentType: 'audio/mp4'),
      );
    } on FirebaseException catch (e) {
      // Retry on specific error codes
      final retryableCodes = ['object-not-found', 'unauthorized', 'canceled'];
      if (retryableCodes.contains(e.code) && attempt <= maxRetries) {
        appLogger('Upload retry due to "${e.code}" (attempt $attempt)...');
        await Future.delayed(const Duration(seconds: 1));
        continue;
      }
      rethrow;
    }
  }
}