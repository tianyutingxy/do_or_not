import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/record_photo_paths.dart';

class RecordPhotoStorage {
  Future<Directory> _photosDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'record_photos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> persistPhoto({
    required int recordId,
    required int slotIndex,
    required String sourcePath,
    String? previousPath,
  }) async {
    await deletePhotoFile(previousPath);

    final dir = await _photosDir();
    final extension = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final destPath = p.join(dir.path, '${recordId}_$slotIndex$extension');
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<void> deletePhotoFile(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteAll(List<String?> paths) async {
    for (final path in RecordPhotoPaths.normalize(paths)) {
      await deletePhotoFile(path);
    }
  }
}
