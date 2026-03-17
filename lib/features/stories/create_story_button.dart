import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:porno_social/providers/auth_providers.dart';
import 'package:porno_social/providers/stories_providers.dart';
import 'package:porno_social/providers/user_providers.dart';

class CreateStoryButton extends ConsumerWidget {
  const CreateStoryButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _showStoryOptions(context, ref),
      backgroundColor: const Color(0xFFe8000a),
      child: const Icon(Icons.add_a_photo),
    );
  }

  void _showStoryOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadMedia(context, ref, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadMedia(context, ref, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadMedia(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(source: source);

      if (pickedFile == null) return;

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading story...')));

      final authState = ref.read(authStateProvider);
      final user = authState.maybeWhen(data: (u) => u, orElse: () => null);
      final userProfileAsync = ref.read(currentUserProfileProvider);
      final userDoc = userProfileAsync.maybeWhen(
        data: (u) => u,
        orElse: () => null,
      );

      if (user == null || userDoc == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated')),
          );
        }
        return;
      }

      // Upload to Firebase Storage
      final fileName =
          'stories/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await storageRef.putFile(File(pickedFile.path));
      final mediaUrl = await uploadTask.ref.getDownloadURL();

      // Add to Firestore
      final storiesRepo = ref.read(storiesRepositoryProvider);
      await storiesRepo.uploadStory(
        mediaUrl: mediaUrl,
        mediaType: 'image',
        authorId: user.uid,
        authorName: userDoc.displayName,
        authorAvatar: userDoc.avatarUrl,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Story posted!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading story: $e')));
      }
    }
  }
}
