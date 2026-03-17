import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AgeVerificationScreen extends StatefulWidget {
  const AgeVerificationScreen({super.key});

  @override
  State<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends State<AgeVerificationScreen> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: [
            _DobStep(onConfirmed: () => setState(() => _step = 1)),
            _IdUploadStep(onUploaded: () => setState(() => _step = 2)),
            const _PendingStep(),
          ][_step],
        ),
      ),
    );
  }
}

class _DobStep extends StatefulWidget {
  final VoidCallback onConfirmed;

  const _DobStep({required this.onConfirmed});

  @override
  State<_DobStep> createState() => _DobStepState();
}

class _DobStepState extends State<_DobStep> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.shield_outlined, color: Color(0xFFe8000a), size: 64),
        const SizedBox(height: 24),
        const Text(
          'Age Verification Required',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'This platform contains adult content. You must be 18 or older to continue. '
          'This is required under the UK Online Safety Act 2023.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFe8000a)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          icon: const Icon(Icons.calendar_today, color: Color(0xFFe8000a)),
          label: Text(
            _selectedDate == null
                ? 'Select date of birth'
                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
            style: const TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1920),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
              helpText: 'Select your date of birth',
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFe8000a),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _selectedDate == null ? null : widget.onConfirmed,
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _IdUploadStep extends StatefulWidget {
  final VoidCallback onUploaded;

  const _IdUploadStep({required this.onUploaded});

  @override
  State<_IdUploadStep> createState() => _IdUploadStepState();
}

class _IdUploadStepState extends State<_IdUploadStep> {
  bool _uploading = false;

  Future<void> _uploadId() async {
    setState(() => _uploading = true);

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        setState(() => _uploading = false);
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _uploading = false);
        return;
      }

      final ref = FirebaseStorage.instance.ref('verifications/$uid/id.jpg');
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('private')
          .doc(uid)
          .set({
            'idDocumentUrl': url,
            'verificationStatus': 'pending',
          }, SetOptions(merge: true));

      setState(() => _uploading = false);
      widget.onUploaded();
    } catch (_) {
      setState(() => _uploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID upload failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.badge_outlined, color: Color(0xFFe8000a), size: 64),
        const SizedBox(height: 24),
        const Text(
          'Upload ID Document',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Please take a photo of your passport, driving licence, or national ID card. '
          'Your ID is encrypted and stored securely. It will be reviewed by our team.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFe8000a),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _uploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.camera_alt, color: Colors.white),
            label: Text(
              _uploading ? 'Uploading...' : 'Take Photo of ID',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: _uploading ? null : _uploadId,
          ),
        ),
      ],
    );
  }
}

class _PendingStep extends StatelessWidget {
  const _PendingStep();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.hourglass_top, color: Color(0xFFe8000a), size: 64),
        SizedBox(height: 24),
        Text(
          'Verification Pending',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Your ID is being reviewed. This usually takes 24-48 hours. '
          'You will receive a notification once approved.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
