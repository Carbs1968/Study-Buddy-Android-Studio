import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ClassMaterialsScreen extends StatefulWidget {
  final String academicYearId;
  final String semesterId;
  final String classId;
  final String className;

  const ClassMaterialsScreen({
    super.key,
    required this.academicYearId,
    required this.semesterId,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassMaterialsScreen> createState() => _ClassMaterialsScreenState();
}

class _ClassMaterialsScreenState extends State<ClassMaterialsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  CollectionReference<Map<String, dynamic>> _materialsRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('academicYears')
        .doc(widget.academicYearId)
        .collection('semesters')
        .doc(widget.semesterId)
        .collection('classes')
        .doc(widget.classId)
        .collection('materials');
  }

  String _fileNameFromPath(String value) {
    final normalized = value.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? 'material.jpg' : segments.last;
  }

  String _safeFileName(String value) {
    final dotIndex = value.lastIndexOf('.');
    final extension = dotIndex >= 0 ? value.substring(dotIndex) : '';
    final base = dotIndex >= 0 ? value.substring(0, dotIndex) : value;
    final safeBase = base
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    final safeName = safeBase.isEmpty ? 'material' : safeBase;
    return '$safeName$extension';
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _addImageFromGallery() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _uploading) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      final file = File(picked.path);
      final sizeBytes = await file.length();
      final materialRef = _materialsRef(uid).doc();
      final originalFileName = _fileNameFromPath(picked.path);
      final safeFileName = _safeFileName(originalFileName);

      final storagePath =
          'classMaterials/$uid/${widget.academicYearId}/${widget.semesterId}/${widget.classId}/${materialRef.id}/$safeFileName';

      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      await storageRef.putFile(
        file,
        SettableMetadata(contentType: picked.mimeType ?? 'image/jpeg'),
      );

      final downloadUrl = await storageRef.getDownloadURL();
      final timestamp = FieldValue.serverTimestamp();

      await materialRef.set({
        'userId': uid,
        'academicYearId': widget.academicYearId,
        'semesterId': widget.semesterId,
        'classId': widget.classId,
        'className': widget.className,
        'materialId': materialRef.id,
        'materialType': 'image',
        'sourceKind': 'gallery',
        'fileName': safeFileName,
        'originalFileName': originalFileName,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'mimeType': picked.mimeType ?? 'image/jpeg',
        'sizeBytes': sizeBytes,
        'status': 'uploaded',
        'extractionStatus': 'not_started',
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Material uploaded.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} Materials'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _addImageFromGallery,
        icon: _uploading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
        label: Text(_uploading ? 'Uploading...' : 'Add image'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _materialsRef(uid).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Could not load materials: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No class materials yet. Add images of notes, worksheets, or whiteboards here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final title = (data['originalFileName'] ?? data['fileName'] ?? 'Material')
                  .toString();
              final type = (data['materialType'] ?? 'image').toString();
              final createdAt = _toDateTime(data['createdAt']);
              final subtitleParts = <String>[
                type,
                if (createdAt != null)
                  '${createdAt.year.toString().padLeft(4, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}',
              ];

              final downloadUrl = (data['downloadUrl'] ?? '').toString();

              return ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(title),
                subtitle: Text(subtitleParts.join(' • ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: downloadUrl.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _MaterialImagePreviewScreen(
                              title: title,
                              imageUrl: downloadUrl,
                            ),
                          ),
                        );
                      },
              );
            },
          );
        },
      ),
    );
  }
}

class _MaterialImagePreviewScreen extends StatelessWidget {
  final String title;
  final String imageUrl;

  const _MaterialImagePreviewScreen({
    required this.title,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5,
        child: Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              final expectedBytes = loadingProgress.expectedTotalBytes;
              final loadedBytes = loadingProgress.cumulativeBytesLoaded;
              final progress = expectedBytes == null
                  ? null
                  : loadedBytes / expectedBytes;

              return CircularProgressIndicator(value: progress);
            },
            errorBuilder: (context, error, stackTrace) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load image: $error',
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
