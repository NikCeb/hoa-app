import 'package:cloud_firestore/cloud_firestore.dart';

class ElectionPosition {
  final String id;
  final String positionName;
  final String description;
  final DateTime deadline;
  final bool isActive;
  final bool endedEarly; // NEW: Track if admin ended early
  final DateTime createdAt;

  ElectionPosition({
    required this.id,
    required this.positionName,
    required this.description,
    required this.deadline,
    required this.isActive,
    this.endedEarly = false, // Default to false
    required this.createdAt,
  });

  factory ElectionPosition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Safe date parsing
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return fallback;
    }

    return ElectionPosition(
      id: doc.id,
      positionName: data['positionName'] ?? '',
      description: data['description'] ?? '',
      deadline: parseDate(
          data['deadline'], DateTime.now().add(const Duration(days: 30))),
      isActive: data['isActive'] ?? true,
      endedEarly: data['endedEarly'] ?? false, // NEW
      createdAt: parseDate(data['createdAt'], DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'positionName': positionName,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'isActive': isActive,
      'endedEarly': endedEarly, // NEW
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Computed properties
  bool get isEnded => endedEarly || DateTime.now().isAfter(deadline); // UPDATED

  bool get canApplyOrVote => isActive && !isEnded;

  String get statusText {
    if (!isActive) return 'Deleted';
    if (endedEarly) return 'Ended Early';
    if (isEnded) return 'Voting Ended';
    return 'Active';
  }

  String get timeRemainingText {
    if (isEnded) return 'Ended';

    final now = DateTime.now();
    final remaining = deadline.difference(now);

    if (remaining.isNegative) return 'Ended';

    if (remaining.inDays > 0) {
      return '${remaining.inDays} day${remaining.inDays > 1 ? 's' : ''} left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hour${remaining.inHours > 1 ? 's' : ''} left';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} minute${remaining.inMinutes > 1 ? 's' : ''} left';
    } else {
      return 'Less than 1 minute left';
    }
  }

  // Format deadline for display
  String get deadlineFormatted {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final month = months[deadline.month - 1];
    final day = deadline.day;
    final year = deadline.year;
    final hour = deadline.hour > 12
        ? deadline.hour - 12
        : (deadline.hour == 0 ? 12 : deadline.hour);
    final minute = deadline.minute.toString().padLeft(2, '0');
    final period = deadline.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $year $hour:$minute $period';
  }
}
