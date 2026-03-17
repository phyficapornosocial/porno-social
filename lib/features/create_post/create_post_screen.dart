import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();

  final List<File> _selectedMedia = [];
  final List<String> _selectedTags = [];

  bool _subscribersOnly = false;
  bool _uploading = false;
  double _uploadProgress = 0;

  static const _availableTags = [
    'Amateur',
    'BDSM',
    'Fetish',
    'Couples',
    'Solo',
    'Cosplay',
    'Fitness',
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final media = await _picker.pickMultipleMedia(limit: 10);
    if (media.isEmpty) return;

    setState(() {
      _selectedMedia
        ..clear()
        ..addAll(media.map((item) => File(item.path)));
    });
  }

  Future<void> _post() async {
    if (_selectedMedia.isEmpty && _captionController.text.trim().isEmpty) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final userData = userDoc.data() ?? <String, dynamic>{};

      final mediaUrls = <String>[];
      var mediaType = 'text';

      for (var i = 0; i < _selectedMedia.length; i++) {
        final file = _selectedMedia[i];
        final lowerPath = file.path.toLowerCase();
        final isVideo =
            lowerPath.endsWith('.mp4') ||
            lowerPath.endsWith('.mov') ||
            lowerPath.endsWith('.avi') ||
            lowerPath.endsWith('.mkv');

        var uploadFile = file;

        if (isVideo) {
          final info = await VideoCompress.compressVideo(
            file.path,
            quality: VideoQuality.MediumQuality,
            deleteOrigin: false,
          );

          if (info?.file != null) {
            uploadFile = info!.file!;
          }

          mediaType = 'video';
        } else {
          mediaType = 'image';
        }

        final ref = FirebaseStorage.instance.ref(
          'posts/$uid/${DateTime.now().millisecondsSinceEpoch}_$i',
        );
        final task = ref.putFile(uploadFile);

        task.snapshotEvents.listen((snap) {
          if (!mounted) return;
          setState(() {
            _uploadProgress =
                (i / _selectedMedia.length) +
                (snap.bytesTransferred /
                    (snap.totalBytes == 0 ? 1 : snap.totalBytes) /
                    _selectedMedia.length);
          });
        });

        await task;
        mediaUrls.add(await ref.getDownloadURL());
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': uid,
        'authorName': userData['displayName'] ?? '',
        'authorAvatar': userData['avatarUrl'] ?? '',
        'content': _captionController.text.trim(),
        'mediaUrls': mediaUrls,
        'mediaType': mediaType,
        'isSubscribersOnly': _subscribersOnly,
        'likeCount': 0,
        'commentCount': 0,
        'tags': _selectedTags,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      await VideoCompress.deleteAllCache();
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('New Post', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _uploading ? null : _post,
            child: const Text(
              'POST',
              style: TextStyle(
                color: Color(0xFFe8000a),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_uploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: const Color(0xFF1E1E1E),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFe8000a),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Uploading ${(_uploadProgress * 100).toInt()}%...',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _captionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: Color(0xFF1E1E1E)),
            const SizedBox(height: 12),
            if (_selectedMedia.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMedia.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedMedia[i],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedMedia.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF333333)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _pickMedia,
              icon: const Icon(Icons.add_photo_alternate, color: Colors.grey),
              label: const Text(
                'Add photo / video',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tags',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  backgroundColor: const Color(0xFF1E1E1E),
                  selectedColor: const Color(0xFFe8000a).withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFFe8000a) : Colors.grey,
                  ),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFFe8000a)
                        : const Color(0xFF333333),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: Color(0xFFe8000a),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Subscribers only',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          'Only paying subscribers can see this post',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _subscribersOnly,
                    onChanged: (value) =>
                        setState(() => _subscribersOnly = value),
                    activeThumbColor: const Color(0xFFe8000a),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
