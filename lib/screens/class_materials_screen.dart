import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
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

  String _extensionForFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) return '';
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _materialTypeForFileName(String fileName) {
    final extension = _extensionForFileName(fileName);

    if (extension == 'pdf') return 'pdf';
    if (extension == 'txt') return 'text';
    if (extension == 'doc' || extension == 'docx') return 'document';
    if (extension == 'csv' || extension == 'xls' || extension == 'xlsx') {
      return 'spreadsheet';
    }
    if (extension == 'ppt' || extension == 'pptx') return 'presentation';

    return 'other';
  }

  String _mimeTypeForFileName(String fileName) {
    final extension = _extensionForFileName(fileName);

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      default:
        return 'application/octet-stream';
    }
  }

  IconData _iconForMaterialType(String type) {
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'spreadsheet':
        return Icons.table_chart_outlined;
      case 'presentation':
        return Icons.slideshow_outlined;
      case 'document':
      case 'text':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _uploadMaterialFile({
    required File file,
    required String originalFileName,
    required String mimeType,
    required String materialType,
    required String sourceKind,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _uploading) return;

    setState(() => _uploading = true);

    try {
      final sizeBytes = await file.length();
      final materialRef = _materialsRef(uid).doc();
      final safeFileName = _safeFileName(originalFileName);

      final storagePath =
          'classMaterials/$uid/${widget.academicYearId}/${widget.semesterId}/${widget.classId}/${materialRef.id}/$safeFileName';

      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      await storageRef.putFile(
        file,
        SettableMetadata(contentType: mimeType),
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
        'materialType': materialType,
        'sourceKind': sourceKind,
        'fileName': safeFileName,
        'originalFileName': originalFileName,
        'storagePath': storagePath,
        'downloadUrl': downloadUrl,
        'mimeType': mimeType,
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

  Future<void> _addImageFromGallery() async {
    if (_uploading) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;

    await _uploadMaterialFile(
      file: File(picked.path),
      originalFileName: _fileNameFromPath(picked.path),
      mimeType: picked.mimeType ?? 'image/jpeg',
      materialType: 'image',
      sourceKind: 'gallery',
    );
  }

  Future<void> _addAcademicFile() async {
    if (_uploading) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: [
        'pdf',
        'txt',
        'doc',
        'docx',
        'csv',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
      ],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final pickedPath = picked.path;

    if (pickedPath == null || pickedPath.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access the selected file.')),
      );
      return;
    }

    final originalFileName = picked.name.trim().isEmpty
        ? _fileNameFromPath(pickedPath)
        : picked.name.trim();

    await _uploadMaterialFile(
      file: File(pickedPath),
      originalFileName: originalFileName,
      mimeType: _mimeTypeForFileName(originalFileName),
      materialType: _materialTypeForFileName(originalFileName),
      sourceKind: 'file',
    );
  }

  Future<void> _showAddMaterialOptions() async {
    if (_uploading) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.add_photo_alternate_outlined),
                title: const Text('Add image'),
                subtitle: const Text('Upload a photo or image from your gallery.'),
                onTap: () {
                  Navigator.pop(context);
                  _addImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Add file'),
                subtitle: const Text('PDF, Word, PowerPoint, text, CSV, or Excel.'),
                onTap: () {
                  Navigator.pop(context);
                  _addAcademicFile();
                },
              ),
            ],
          ),
        );
      },
    );
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
        onPressed: _uploading ? null : _showAddMaterialOptions,
        icon: _uploading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_outlined),
        label: Text(_uploading ? 'Uploading...' : 'Add material'),
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
                leading: Icon(_iconForMaterialType(type)),
                title: Text(title),
                subtitle: Text(subtitleParts.join(' • ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: downloadUrl.isEmpty
                    ? null
                    : () {
                        if (type == 'image') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _MaterialImagePreviewScreen(
                                title: title,
                                imageUrl: downloadUrl,
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _MaterialFileDetailsScreen(
                              title: title,
                              materialType: type,
                              downloadUrl: downloadUrl,
                              mimeType: (data['mimeType'] ?? '').toString(),
                              sizeBytes: data['sizeBytes'],
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

class _MaterialFileDetailsScreen extends StatelessWidget {
  final String title;
  final String materialType;
  final String downloadUrl;
  final String mimeType;
  final dynamic sizeBytes;

  const _MaterialFileDetailsScreen({
    required this.title,
    required this.materialType,
    required this.downloadUrl,
    required this.mimeType,
    required this.sizeBytes,
  });

  String _formatSize(dynamic value) {
    final bytes = value is int ? value : int.tryParse(value.toString());
    if (bytes == null) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text('Type: $materialType'),
          Text('MIME type: ${mimeType.isEmpty ? 'Unknown' : mimeType}'),
          Text('Size: ${_formatSize(sizeBytes)}'),
          const SizedBox(height: 24),
          const Text(
            'This file is uploaded and saved as class material. File preview and AI text extraction will be added in a later step.',
          ),
          const SizedBox(height: 16),
          SelectableText(
            downloadUrl,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
