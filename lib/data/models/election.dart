import 'package:cloud_firestore/cloud_firestore.dart';

enum ElectionStatus {
  upcoming,
  active,
  closed,
}

class Election {
  final String id;
  final String electionName;
  final DateTime timeStart;
  final DateTime timeEnd;
  final bool isActive;
  final Map<String, dynamic> candidateResults;
  final int totalVerifiedVoters;
  final ElectionStatus status;
  final DateTime createdAt;

  Election({
    required this.id,
    required this.electionName,
    required this.timeStart,
    required this.timeEnd,
    required this.isActive,
    required this.candidateResults,
    required this.totalVerifiedVoters,
    required this.status,
    required this.createdAt,
  });

  factory Election.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Election(
      id: doc.id,
      electionName: data['electionName'] ?? '',
      timeStart: (data['timeStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeEnd: (data['timeEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? false,
      candidateResults: data['candidateResults'] ?? {},
      totalVerifiedVoters: data['totalVerifiedVoters'] ?? 0,
      status: _statusFromString(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'electionName': electionName,
      'timeStart': Timestamp.fromDate(timeStart),
      'timeEnd': Timestamp.fromDate(timeEnd),
      'isActive': isActive,
      'candidateResults': candidateResults,
      'totalVerifiedVoters': totalVerifiedVoters,
      'status': status.name.toUpperCase(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static ElectionStatus _statusFromString(dynamic status) {
    if (status == null) return ElectionStatus.upcoming;
    switch (status.toString().toUpperCase()) {
      case 'ACTIVE':
        return ElectionStatus.active;
      case 'CLOSED':
        return ElectionStatus.closed;
      default:
        return ElectionStatus.upcoming;
    }
  }

  String get statusText {
    switch (status) {
      case ElectionStatus.upcoming:
        return 'Upcoming';
      case ElectionStatus.active:
        return 'Active';
      case ElectionStatus.closed:
        return 'Closed';
    }
  }

  bool get isOpen {
    final now = DateTime.now();
    return isActive &&
        status == ElectionStatus.active &&
        now.isAfter(timeStart) &&
        now.isBefore(timeEnd);
  }

  bool get hasEnded {
    return DateTime.now().isAfter(timeEnd);
  }

  String get timeRemainingText {
    if (!isOpen) return 'Closed';

    final now = DateTime.now();
    final remaining = timeEnd.difference(now);

    if (remaining.inDays > 0) {
      return '${remaining.inDays} day${remaining.inDays > 1 ? 's' : ''} left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hour${remaining.inHours > 1 ? 's' : ''} left';
    } else {
      return '${remaining.inMinutes} minute${remaining.inMinutes > 1 ? 's' : ''} left';
    }
  }
}
