import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:xml/xml.dart';

import '../l10n/app_localizations.dart';

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

  String _formatMaterialTypeLabel(
    BuildContext context,
    String type,
  ) {
    final strings = AppLocalizations.of(context);

    switch (type.toLowerCase()) {
      case 'image':
        return strings.materialTypeImage;
      case 'pdf':
        return strings.materialTypePdf;
      case 'spreadsheet':
        return strings.materialTypeSpreadsheet;
      case 'presentation':
        return strings.materialTypePresentation;
      case 'document':
        return strings.materialTypeDocument;
      case 'text':
        return strings.materialTypeText;
      default:
        return strings.materialTypeFile;
    }
  }

  String _formatMaterialDate(
    BuildContext context,
    DateTime date,
  ) {
    final strings = AppLocalizations.of(context);
    final local = date.toLocal();
    final formattedDate =
        MaterialLocalizations.of(context).formatMediumDate(local);

    return strings.materialAddedDate(formattedDate);
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

    String? uploadedStoragePath;
    var materialMetadataSaved = false;

    try {
      final sizeBytes = await file.length();
      final materialRef = _materialsRef(uid).doc();
      final safeFileName = _safeFileName(originalFileName);

      final storagePath =
          'classMaterials/$uid/${widget.academicYearId}/${widget.semesterId}/${widget.classId}/${materialRef.id}/$safeFileName';
      uploadedStoragePath = storagePath;

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
        'materialScope': 'class',
        'topicId': null,
        'topicName': null,
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
      materialMetadataSaved = true;

      final classRef = _materialsRef(uid).parent!;
      try {
        await classRef.set({
          'lastActivityAt': FieldValue.serverTimestamp(),
          'lastMaterialAt': FieldValue.serverTimestamp(),
          'hasMaterials': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (metadataError, stackTrace) {
        debugPrint('Failed to update class material metadata: $metadataError');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).materialUploaded)),
      );
    } catch (error) {
      final orphanedStoragePath = uploadedStoragePath;
      if (orphanedStoragePath != null && !materialMetadataSaved) {
        try {
          await FirebaseStorage.instance.ref().child(orphanedStoragePath).delete();
        } catch (cleanupError, stackTrace) {
          debugPrint('Failed to delete orphaned material upload: $cleanupError');
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).materialUploadFailed)),
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
        SnackBar(content: Text(AppLocalizations.of(context).selectedFileUnavailable)),
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
                title: Text(AppLocalizations.of(context).addImage),
                subtitle: Text(AppLocalizations.of(context).addImageDescription),
                onTap: () {
                  Navigator.pop(context);
                  _addImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: Text(AppLocalizations.of(context).addFile),
                subtitle: Text(AppLocalizations.of(context).addFileDescription),
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
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context);

    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(strings.notSignedIn)),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.materialsTitle(widget.className)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
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
        label: Text(_uploading ? strings.uploading : strings.addMaterial),
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
                  strings.couldNotLoadMaterials,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 0,
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.upload_file_outlined,
                          size: 42,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          strings.noClassMaterials,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          strings.noClassMaterialsDescription,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final title = (data['originalFileName'] ?? data['fileName'] ?? strings.materialFallbackName)
                  .toString();
              final type = (data['materialType'] ?? 'image').toString();
              final createdAt = _toDateTime(data['createdAt']);
              final subtitleParts = <String>[
                _formatMaterialTypeLabel(context, type),
                if (createdAt != null) _formatMaterialDate(context, createdAt),
              ];

              final downloadUrl = (data['downloadUrl'] ?? '').toString();
              final storagePath = (data['storagePath'] ?? '').toString();
              final mimeType = (data['mimeType'] ?? '').toString();
              final materialRef = docs[index].reference;

              return Card(
                elevation: 0,
                color: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: Icon(
                    _iconForMaterialType(type),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  subtitle: Text(
                    subtitleParts.join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                                materialRef: materialRef,
                                storagePath: storagePath,
                              ),
                            ),
                          );
                          return;
                        }

                        if (type == 'pdf') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _MaterialPdfPreviewScreen(
                                title: title,
                                pdfUrl: downloadUrl,
                                materialRef: materialRef,
                                storagePath: storagePath,
                              ),
                            ),
                          );
                          return;
                        }

                        final isDocx = title.toLowerCase().endsWith('.docx') ||
                            mimeType.contains(
                              'openxmlformats-officedocument.wordprocessingml.document',
                            );

                        if (isDocx) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _MaterialDocxTextPreviewScreen(
                                title: title,
                                docxUrl: downloadUrl,
                                materialRef: materialRef,
                                storagePath: storagePath,
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
                              mimeType: mimeType,
                              sizeBytes: data['sizeBytes'],
                              materialRef: materialRef,
                              storagePath: storagePath,
                            ),
                          ),
                        );
                      },
                ),
              );
            },
          );
        },
      ),
    );
  }
}


Future<void> _deleteMaterial(
  BuildContext context, {
  required DocumentReference<Map<String, dynamic>> materialRef,
  required String storagePath,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context).deleteMaterialTitle),
      content: Text(
        AppLocalizations.of(context).deleteMaterialMessage,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(AppLocalizations.of(context).delete),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    if (storagePath.trim().isNotEmpty) {
      try {
        await FirebaseStorage.instance.ref().child(storagePath).delete();
      } catch (storageError) {
        final message = storageError.toString();
        final objectAlreadyMissing = message.contains('object-not-found') ||
            message.contains('Object does not exist') ||
            message.contains('No object exists');

        if (!objectAlreadyMissing) {
          rethrow;
        }
      }
    }

    await materialRef.delete();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).materialDeleted)),
    );

    Navigator.pop(context);
  } catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).deleteFailed)),
    );
  }
}

class _MaterialImagePreviewScreen extends StatelessWidget {
  final String title;
  final String imageUrl;
  final DocumentReference<Map<String, dynamic>> materialRef;
  final String storagePath;

  const _MaterialImagePreviewScreen({
    required this.title,
    required this.imageUrl,
    required this.materialRef,
    required this.storagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).deleteMaterialTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteMaterial(
              context,
              materialRef: materialRef,
              storagePath: storagePath,
            ),
          ),
        ],
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
                  AppLocalizations.of(context).imageLoadFailed,
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


class _MaterialPdfPreviewScreen extends StatelessWidget {
  final String title;
  final String pdfUrl;
  final DocumentReference<Map<String, dynamic>> materialRef;
  final String storagePath;

  const _MaterialPdfPreviewScreen({
    required this.title,
    required this.pdfUrl,
    required this.materialRef,
    required this.storagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).deleteMaterialTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteMaterial(
              context,
              materialRef: materialRef,
              storagePath: storagePath,
            ),
          ),
        ],
      ),
      body: PdfViewer.uri(
        Uri.parse(pdfUrl),
      ),
    );
  }
}


Future<Uint8List> _downloadMaterialBytes(String url) async {
  final request = await HttpClient().getUrl(Uri.parse(url));
  final response = await request.close();

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Download failed with status ${response.statusCode}.');
  }

  final bytes = <int>[];
  await for (final chunk in response) {
    bytes.addAll(chunk);
  }

  return Uint8List.fromList(bytes);
}

String _extractTextFromDocxBytes(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final documentFile = archive.files
      .where((file) => file.name == 'word/document.xml')
      .firstOrNull;

  if (documentFile == null) {
    throw Exception('DOCX document body was not found.');
  }

  final xmlText = utf8.decode(documentFile.content);

  final document = XmlDocument.parse(xmlText);
  final paragraphs = document.descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == 'p');

  final paragraphText = <String>[];

  for (final paragraph in paragraphs) {
    final text = paragraph.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 't')
        .map((element) => element.innerText)
        .join();

    final trimmed = text.trim();
    if (trimmed.isNotEmpty) {
      paragraphText.add(trimmed);
    }
  }

  if (paragraphText.isNotEmpty) {
    return paragraphText.join('\n\n');
  }

  final fallbackText = document.descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == 't')
      .map((element) => element.innerText)
      .join(' ')
      .trim();

  if (fallbackText.isEmpty) {
    throw Exception('No readable DOCX text found.');
  }

  return fallbackText;
}

class _MaterialDocxTextPreviewScreen extends StatelessWidget {
  final String title;
  final String docxUrl;
  final DocumentReference<Map<String, dynamic>> materialRef;
  final String storagePath;

  const _MaterialDocxTextPreviewScreen({
    required this.title,
    required this.docxUrl,
    required this.materialRef,
    required this.storagePath,
  });

  Future<String> _loadText() async {
    final bytes = await _downloadMaterialBytes(docxUrl);
    return _extractTextFromDocxBytes(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).deleteMaterialTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteMaterial(
              context,
              materialRef: materialRef,
              storagePath: storagePath,
            ),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _loadText(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).docxPreviewFailed,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docText = snapshot.data?.trim() ?? '';

          if (docText.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppLocalizations.of(context).docxNoReadableText,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              SelectableText(docText),
            ],
          );
        },
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
  final DocumentReference<Map<String, dynamic>> materialRef;
  final String storagePath;

  const _MaterialFileDetailsScreen({
    required this.title,
    required this.materialType,
    required this.downloadUrl,
    required this.mimeType,
    required this.sizeBytes,
    required this.materialRef,
    required this.storagePath,
  });

  String _formatMaterialDetailsTypeLabel(
    BuildContext context,
    String type,
  ) {
    final strings = AppLocalizations.of(context);

    switch (type.toLowerCase()) {
      case 'image':
        return strings.materialTypeImage;
      case 'pdf':
        return strings.materialTypePdf;
      case 'spreadsheet':
        return strings.materialTypeSpreadsheet;
      case 'presentation':
        return strings.materialTypePresentation;
      case 'document':
        return strings.materialTypeDocument;
      case 'text':
        return strings.materialTypeText;
      default:
        return strings.materialTypeFile;
    }
  }

  String _formatSize(BuildContext context, dynamic value) {
    final bytes = value is int ? value : int.tryParse(value.toString());
    if (bytes == null) return AppLocalizations.of(context).unknownSize;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).deleteMaterialTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteMaterial(
              context,
              materialRef: materialRef,
              storagePath: storagePath,
            ),
          ),
        ],
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
          Text(
            AppLocalizations.of(context).materialTypeValue(
              _formatMaterialDetailsTypeLabel(context, materialType),
            ),
          ),
          Text(
            AppLocalizations.of(context).materialSizeValue(
              _formatSize(context, sizeBytes),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).materialPreviewUnavailable,
          ),
        ],
      ),
    );
  }
}
