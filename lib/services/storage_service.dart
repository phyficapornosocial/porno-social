import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;
  final Uuid _uuid;

  StorageService({FirebaseStorage? storage, ImagePicker? picker, Uuid? uuid})
    : _storage = storage ?? FirebaseStorage.instance,
      _picker = picker ?? ImagePicker(),
      _uuid = uuid ?? const Uuid();

  Future<String?> pickAndUploadImage({
    required String folder,
    required String uid,
    ImageSource source = ImageSource.gallery,
    int maxWidthPx = 1080,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: maxWidthPx.toDouble(),
      imageQuality: 85,
    );

    if (picked == null) return null;
    return uploadFile(file: File(picked.path), folder: folder, uid: uid);
  }

  Future<String?> pickAndUploadVideo({
    required String folder,
    required String uid,
  }) async {
    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );

    if (picked == null) return null;
    return uploadFile(file: File(picked.path), folder: folder, uid: uid);
  }

  Future<String> uploadFile({
    required File file,
    required String folder,
    required String uid,
  }) async {
    final ext = file.path.split('.').last;
    final filename = '${_uuid.v4()}.$ext';
    final ref = _storage.ref('$folder/$uid/$filename');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  UploadTask uploadWithProgress({
    required File file,
    required String folder,
    required String uid,
  }) {
    final ext = file.path.split('.').last;
    final filename = '${_uuid.v4()}.$ext';
    final ref = _storage.ref('$folder/$uid/$filename');
    return ref.putFile(file);
  }
}
