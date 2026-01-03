import 'package:flutter/material.dart';
import '../../../../data/models/announcement.dart';
import '../../../../data/repositories/announcement_repository.dart';

class UserAnnouncementsScreen extends StatelessWidget {
  const UserAnnouncementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final repository = AnnouncementRepository();

    return StreamBuilder<List<Announcement>>(
      stream: repository.getActiveAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            return _buildAnnouncementCard(
              context,
              announcements[index],
              repository,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Announcements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for updates',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    Announcement announcement,
    AnnouncementRepository repository,
  ) {
    Color backgroundColor;
    Color iconColor;

    switch (announcement.type) {
      case AnnouncementType.urgent:
        backgroundColor = const Color(0xFFFEF3C7); // Yellow
        iconColor = const Color(0xFFF59E0B);
        break;
      case AnnouncementType.event:
        backgroundColor = const Color(0xFFDCFCE7); // Green
        iconColor = const Color(0xFF10B981);
        break;
      case AnnouncementType.maintenance:
        backgroundColor = const Color(0xFFFEE2E2); // Red
        iconColor = const Color(0xFFEF4444);
        break;
      default:
        backgroundColor = const Color(0xFFDEDEFE); // Blue
        iconColor = const Color(0xFF6366F1);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: backgroundColor,
      child: InkWell(
        onTap: () {
          // Increment view count when tapped
          repository.incrementViewCount(announcement.id);
          _showAnnouncementDetails(context, announcement);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        announcement.typeIcon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Content preview
              Text(
                announcement.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Posted ${announcement.timeAgo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetails(
    BuildContext context,
    Announcement announcement,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon and Title
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getIconColor(announcement.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        announcement.typeIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          announcement.typeDisplayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Posted time
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Posted ${announcement.timeAgo}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Content
              Text(
                announcement.content,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconColor(AnnouncementType type) {
    switch (type) {
      case AnnouncementType.urgent:
        return const Color(0xFFF59E0B);
      case AnnouncementType.event:
        return const Color(0xFF10B981);
      case AnnouncementType.maintenance:
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6366F1);
    }
  }
}
