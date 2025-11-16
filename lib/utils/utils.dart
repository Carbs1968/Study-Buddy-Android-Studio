// Enhanced: surface detailed Cloud Functions errors to the UI
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'app_logger.dart';

// ✅ Single Functions handle (same app-wide region as your backend)
late FirebaseFunctions functions;

Future<String> fetchTranscript(String recordingId) async {
  try {
    final callable = functions.httpsCallable('getTranscriptText');
    final result = await callable.call({'recordingId': recordingId});
    final data = result.data as Map;
    return (data['text'] as String?) ?? '';
  } on FirebaseFunctionsException catch (e) {
    appLogger('getTranscriptText failed: code=${e.code} message=${e.message} details=${e.details}');
    throw 'Transcript error (${e.code}): ${e.message ?? 'unknown error'}';
  } catch (e) {
    appLogger('getTranscriptText failed: $e');
    throw 'Transcript fetch failed: $e';
  }
}

// -----------------------------
// MULTILINGUAL TRANSLATION FIX
// -----------------------------


// --------- FIREBASE STORAGE: Transcripts and Profile Images ---------

// Example: Upload transcript file to Storage under /transcripts/{uid}/
Future<String> uploadTranscriptFile(File transcriptFile, String filename) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final storagePath = 'transcripts/$uid/$filename';
  appLogger('Uploading transcript to path=$storagePath');
  final ref = FirebaseStorage.instance
      .ref()
      .child('transcripts')
      .child(uid)
      .child(filename);
  final task = ref.putFile(
    transcriptFile,
    SettableMetadata(contentType: 'text/plain'),
  );
  await task;
  return await ref.getDownloadURL();
}

// Example: Upload profile image to Storage under /profile_pics/{uid}/
Future<String> uploadProfileImage(File imageFile, String filename) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final storagePath = 'profile_pics/$uid/$filename';
  appLogger('Uploading profile image to path=$storagePath');
  final ref = FirebaseStorage.instance
      .ref()
      .child('profile_pics')
      .child(uid)
      .child(filename);
  final task = ref.putFile(
    imageFile,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  await task;
  return await ref.getDownloadURL();
}

// Upload profile image to /profile_images/{uid}/{filename} with contentType image/jpeg
Future<String> uploadProfileImageV2(File imageFile, String filename) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final storagePath = 'profile_images/$uid/$filename';
  appLogger('Uploading profile image V2 to path=$storagePath');
  final ref = FirebaseStorage.instance
      .ref()
      .child('profile_images')
      .child(uid)
      .child(filename);
  final task = ref.putFile(
    imageFile,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  await task;
  return await ref.getDownloadURL();
}

// Upload user photo to /user_photos/{uid}/{filename} with contentType image/jpeg
Future<String> uploadUserPhoto(File imageFile, String filename) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final storagePath = 'user_photos/$uid/$filename';
  appLogger('Uploading user photo to path=$storagePath');
  final ref = FirebaseStorage.instance
      .ref()
      .child('user_photos')
      .child(uid)
      .child(filename);
  final task = ref.putFile(
    imageFile,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  await task;
  return await ref.getDownloadURL();
}