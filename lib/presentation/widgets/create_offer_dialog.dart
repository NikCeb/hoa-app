import 'package:flutter/material.dart';
import '../../../data/models/help_request.dart';
import '../../../data/repositories/request_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Shows a dialog to create an offer to help with a request
Future<void> showCreateOfferDialog({
  required BuildContext context,
  required HelpRequest request,
}) async {
  final repository = RequestRepository();
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final user = auth.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please log in to offer help'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Check if user is trying to help their own request
  if (request.requesterId == user.uid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You cannot offer help on your own request'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // Fetch user data from Firestore to get their name
  String userName;
  try {
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final firstName = userData['firstName'] ?? '';
      final lastName = userData['lastName'] ?? '';
      userName = '$firstName $lastName'.trim();

      // Fallback if name is empty
      if (userName.isEmpty) {
        userName = user.displayName ?? user.email ?? 'Anonymous';
      }
    } else {
      userName = user.displayName ?? user.email ?? 'Anonymous';
    }
  } catch (e) {
    userName = user.displayName ?? user.email ?? 'Anonymous';
  }

  final messageController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Offer to Help'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offering help for: ${request.title}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Message (Optional)',
                hintText: 'I can help with this...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await repository.createOffer(
                requestId: request.id,
                helperName: userName,
                message: messageController.text.trim().isEmpty
                    ? null
                    : messageController.text.trim(),
              );

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Offer submitted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to submit offer: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
          ),
          child: const Text('Submit Offer'),
        ),
      ],
    ),
  );
}

/// Button widget to trigger offer dialog
class OfferToHelpButton extends StatelessWidget {
  final HelpRequest request;

  const OfferToHelpButton({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show button if request is completed
    if (request.isCompleted) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () => showCreateOfferDialog(
        context: context,
        request: request,
      ),
      icon: const Icon(Icons.volunteer_activism),
      label: const Text('Offer to Help'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
