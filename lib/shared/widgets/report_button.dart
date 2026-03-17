import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const List<Map<String, String>> _reportReasons = [
  {'label': 'Illegal content', 'value': 'illegal'},
  {'label': 'Involves minor', 'value': 'underage'},
  {'label': 'Spam', 'value': 'spam'},
  {'label': 'Harassment', 'value': 'harassment'},
  {'label': 'Other', 'value': 'other'},
];

Future<void> showReportDialog(
  BuildContext context, {
  required String targetType,
  required String targetId,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You must be signed in to report content.')),
    );
    return;
  }

  String? selectedReason;
  final descriptionController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111111),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report content',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._reportReasons.map(
              (reason) => ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => setState(() => selectedReason = reason['value']),
                leading: Icon(
                  selectedReason == reason['value']
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selectedReason == reason['value']
                      ? const Color(0xFFe8000a)
                      : Colors.grey,
                ),
                title: Text(
                  reason['label']!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Additional details (optional)',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe8000a),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: selectedReason == null
                    ? null
                    : () async {
                        await FirebaseFirestore.instance
                            .collection('reports')
                            .add({
                              'reporterUid': user.uid,
                              'targetType': targetType,
                              'targetId': targetId,
                              'reason': selectedReason,
                              'description': descriptionController.text.trim(),
                              'status': 'pending',
                              'createdAt': FieldValue.serverTimestamp(),
                              'reviewedBy': null,
                              'reviewedAt': null,
                            });

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Report submitted. Thank you.'),
                            ),
                          );
                        }
                      },
                child: const Text(
                  'Submit Report',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  descriptionController.dispose();
}

class ReportButton extends StatelessWidget {
  final String targetType;
  final String targetId;

  const ReportButton({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.flag_outlined, color: Colors.grey, size: 20),
      onPressed: () =>
          showReportDialog(context, targetType: targetType, targetId: targetId),
    );
  }
}
