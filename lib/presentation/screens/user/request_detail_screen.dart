import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoa_application/core/utils/message_alert.dart';
import '../../../core/constants/app_colors.dart';
import '../../../../data/models/help_request.dart';
import '../../../../data/models/offer.dart';
import '../../../../data/repositories/request_repository.dart';
import 'edit_help_request_screen.dart';

/// Request Detail Screen - Shows detailed view of a single request
///
/// Features:
/// - 3 tabs: Details, Offers (with count), Chat
/// - Accept/reject offer buttons
/// - Mark as complete button
/// - Delete button (for own open requests)
/// - Edit button (for own open requests)
/// - Auto-refresh after edit
/// - Real-time offer updates
///
/// Data Flow:
/// User taps request card → Navigator.push(RequestDetailScreen)
///   ↓
/// StreamBuilder monitors offers
///   ↓
/// Tab shows updated offer count
class RequestDetailScreen extends StatefulWidget {
  final HelpRequest request;

  const RequestDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen>
    with SingleTickerProviderStateMixin {
  final RequestRepository _repository = RequestRepository();
  late TabController _tabController;

  final _auth = FirebaseAuth.instance;

  // Current request data (updates after edit)
  late HelpRequest _currentRequest;

  bool get _isMyRequest {
    return _currentRequest.requesterId == _auth.currentUser?.uid;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentRequest = widget.request; // Initialize with passed request
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Refresh request data from Firestore
  Future<void> _refreshRequest() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('help_requests')
          .doc(_currentRequest.id)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _currentRequest = HelpRequest.fromFirestore(doc);
        });
      }
    } catch (e) {
      // Silently fail - not critical
      debugPrint('Error refreshing request: $e');
    }
  }

  /// Delete the current request (only for open status)
  Future<void> _deleteRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text(
          'Are you sure you want to delete this request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Delete the request document
        await FirebaseFirestore.instance
            .collection('help_requests')
            .doc(_currentRequest.id)
            .delete();

        if (mounted) {
          // Go back to previous screen
          Navigator.pop(context);

          // Show success message
          _showError('Request deleted successfully', Colors.green);
        }
      } catch (e) {
        if (mounted) {
          _showError('Error deleting request: $e', Colors.red);
        }
      }
    }
  }

  /// Navigate to edit screen and refresh on success
  Future<void> _editRequest() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditHelpRequestScreen(request: _currentRequest),
      ),
    );

    // If edit was successful, refresh the request data
    if (result == true && mounted) {
      await _refreshRequest();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: const Text('Request Details'),
        elevation: 0,
      ),

      body: Column(
        children: [
          // Status badge header
          _buildStatusHeader(),

          // Tab bar
          Container(
            color: Colors.white,
            child: StreamBuilder<List<Offer>>(
              stream: _repository.getRequestOffers(_currentRequest.id),
              builder: (context, snapshot) {
                final offers = snapshot.data ?? [];
                final offerCount = offers.length;

                return TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2563EB),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF2563EB),
                  tabs: [
                    const Tab(text: 'Details'),
                    Tab(text: 'Offers ($offerCount)'),
                    const Tab(text: 'Chat'),
                  ],
                );
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildOffersTab(),
                _buildChatTab(),
              ],
            ),
          ),
        ],
      ),

      // Bottom action button
      bottomNavigationBar:
          _currentRequest.isInProgress ? _buildCompleteButton() : null,
    );
  }

  /// Status badge at top
  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Color(
              int.parse(_currentRequest.statusColor.replaceFirst('#', '0xFF')))
          .withOpacity(0.1),
      child: Center(
        child: Text(
          _currentRequest.statusText,
          style: TextStyle(
            color: Color(int.parse(
                _currentRequest.statusColor.replaceFirst('#', '0xFF'))),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// DETAILS TAB - Shows request information
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and category badge
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentRequest.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentRequest.categoryText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Requester info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  _currentRequest.requesterName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentRequest.requesterName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_currentRequest.tulongCount} Tulong',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Description section
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentRequest.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Info cards
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.people_outline,
                  label: 'Helpers Needed',
                  value: '${_currentRequest.helpersNeeded} person',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.location_on_outlined,
                  label: 'Distance',
                  value: _currentRequest.distanceText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildInfoCard(
            icon: Icons.access_time,
            label: 'Posted',
            value: _currentRequest.timeAgo,
          ),

          const SizedBox(height: 32),

          // ============================================
          // OFFER TO HELP BUTTON (only if not your request)
          // ============================================
          if (!_isMyRequest && _currentRequest.isOpen)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _showOfferDialog,
                icon: const Icon(Icons.volunteer_activism),
                label: const Text(
                  'Offer to Help',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

          // ============================================
          // YOUR REQUEST SECTION (with Edit & Delete buttons)
          // ============================================
          if (_isMyRequest) ...[
            // Info box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is your request',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // EDIT & DELETE BUTTONS (only for open requests)
            if (_currentRequest.isOpen) ...[
              const SizedBox(height: 16),

              // Edit & Delete buttons side by side
              Row(
                children: [
                  // EDIT BUTTON
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _editRequest,
                        icon: const Icon(Icons.edit, size: 20),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // DELETE BUTTON
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _deleteRequest,
                        icon: const Icon(Icons.delete, size: 20),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// OFFERS TAB - Shows list of people who offered to help
  Widget _buildOffersTab() {
    return StreamBuilder<List<Offer>>(
      stream: _repository.getRequestOffers(_currentRequest.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading offers: ${snapshot.error}'),
          );
        }

        final offers = snapshot.data ?? [];

        if (offers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No offers yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Waiting for neighbors to offer help',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            return _buildOfferCard(offer);
          },
        );
      },
    );
  }

  /// Individual offer card with accept/reject buttons
  Widget _buildOfferCard(Offer offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Helper info row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    offer.helperName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.helperName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        offer.timeAgo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(int.parse(
                            offer.statusColor.replaceFirst('#', '0xFF')))
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    offer.statusText,
                    style: TextStyle(
                      color: Color(int.parse(
                          offer.statusColor.replaceFirst('#', '0xFF'))),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Message if provided
            if (offer.message != null && offer.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  offer.message!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],

            // Accept/Reject buttons (only if pending and request is still open)
            if (offer.isPending && _currentRequest.isOpen) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOffer(offer),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectOffer(offer),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// CHAT TAB - Coming soon
  Widget _buildChatTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Chat feature coming soon!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Complete request button
  Widget _buildCompleteButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _completeRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Mark as Complete',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================
  Future<void> _showOfferDialog() async {
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offer to Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offering help for: ${_currentRequest.title}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Offer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = _auth.currentUser;
        if (user == null) {
          throw Exception('Please log in to offer help');
        }

        // Get user name
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data() as Map<String, dynamic>;
        final userName = '${userData['firstName']} ${userData['lastName']}';

        // Create offer
        await _repository.createOffer(
          requestId: _currentRequest.id,
          helperName: userName,
          message: messageController.text.trim().isEmpty
              ? null
              : messageController.text.trim(),
        );

        if (mounted) {
          _showError('Offer submitted successfully!', Colors.green);
        }
      } catch (e) {
        if (mounted) {
          _showError('You have already offered to help for this request.',
              Colors.orange);
        }
      }
    }

    messageController.dispose();
  }

  Future<void> _acceptOffer(Offer offer) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Offer'),
        content: Text(
          'Accept ${offer.helperName}\'s offer? '
          'This will reject all other pending offers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repository.acceptOffer(
        requestId: _currentRequest.id,
        offerId: offer.id,
      );

      if (mounted) {
        _showError('Accepted ${offer.helperName}\'s offer!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showError('Try again later.', Colors.red);
      }
    }
  }

  Future<void> _rejectOffer(Offer offer) async {
    try {
      await _repository.rejectOffer(offer.id);

      if (mounted) {
        _showError('Rejected ${offer.helperName}\'s offer', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showError('Try again later.', Colors.red);
      }
    }
  }

  Future<void> _completeRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Request'),
        content: const Text('Mark this request as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repository.completeRequest(_currentRequest.id);

      if (mounted) {
        Navigator.pop(context); // Go back to list
        _showError('Request marked as completed!', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showError('Try again later.', Colors.red);
      }
    }
  }

  void _showError(String message, Color? color) {
    showMessage(context, message, bgColor: color ?? AppColors.grey);
  }
}
