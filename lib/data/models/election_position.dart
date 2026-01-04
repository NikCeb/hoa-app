import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ElectionPosition {
  final String id;
  final String positionName;
  final String electionId;
  final int maxWinners;
  final int sortOrder;
  final bool isActive;
  final DateTime nominationStart;
  final DateTime nominationEnd;
  final DateTime votingStart;
  final DateTime votingEnd;

  ElectionPosition({
    required this.id,
    required this.positionName,
    required this.electionId,
    required this.maxWinners,
    required this.sortOrder,
    required this.isActive,
    required this.nominationStart,
    required this.nominationEnd,
    required this.votingStart,
    required this.votingEnd,
  });

  factory ElectionPosition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Better date parsing with fallbacks
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return fallback;
    }

    // Default dates: nomination starts now, ends in 7 days
    // Voting starts after nomination, ends in 14 days
    final defaultNomStart = DateTime.now();
    final defaultNomEnd = DateTime.now().add(const Duration(days: 7));
    final defaultVoteStart = DateTime.now().add(const Duration(days: 7));
    final defaultVoteEnd = DateTime.now().add(const Duration(days: 14));

    return ElectionPosition(
      id: doc.id,
      positionName: data['positionName'] ?? '',
      electionId: data['electionId'] ?? '',
      maxWinners: data['maxWinners'] ?? 1,
      sortOrder: data['sortOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
      nominationStart: parseDate(data['nominationStart'], defaultNomStart),
      nominationEnd: parseDate(data['nominationEnd'], defaultNomEnd),
      votingStart: parseDate(data['votingStart'], defaultVoteStart),
      votingEnd: parseDate(data['votingEnd'], defaultVoteEnd),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'positionName': positionName,
      'electionId': electionId,
      'maxWinners': maxWinners,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'nominationStart': Timestamp.fromDate(nominationStart),
      'nominationEnd': Timestamp.fromDate(nominationEnd),
      'votingStart': Timestamp.fromDate(votingStart),
      'votingEnd': Timestamp.fromDate(votingEnd),
    };
  }

  // Computed properties
  bool get isNominationOpen {
    final now = DateTime.now();
    final result =
        isActive && now.isAfter(nominationStart) && now.isBefore(nominationEnd);
    return result;
  }

  bool get isVotingOpen {
    final now = DateTime.now();
    return isActive && now.isAfter(votingStart) && now.isBefore(votingEnd);
  }

  bool get hasNominationStarted {
    return DateTime.now().isAfter(nominationStart);
  }

  bool get hasNominationEnded {
    return DateTime.now().isAfter(nominationEnd);
  }

  bool get hasVotingStarted {
    return DateTime.now().isAfter(votingStart);
  }

  bool get hasVotingEnded {
    return DateTime.now().isAfter(votingEnd);
  }

  bool get isUpcoming {
    return !hasNominationStarted;
  }

  String get statusText {
    if (isNominationOpen) return 'Nominations Open';
    if (isVotingOpen) return 'Voting Open';
    if (hasVotingEnded) return 'Closed';
    if (hasNominationEnded && !hasVotingStarted) return 'Awaiting Voting';
    if (hasNominationEnded) return 'Nominations Closed';
    if (isUpcoming) return 'Upcoming';
    return 'Upcoming';
  }

  Color get statusColor {
    if (isNominationOpen) return const Color(0xFF3B82F6); // Blue
    if (isVotingOpen) return const Color(0xFF10B981); // Green
    if (hasVotingEnded) return const Color(0xFF6B7280); // Grey
    if (hasNominationEnded && !hasVotingStarted) {
      return const Color(0xFF8B5CF6); // Purple - awaiting voting
    }
    return const Color(0xFFF59E0B); // Orange for upcoming
  }

  String get timeRemainingText {
    final now = DateTime.now();

    if (isUpcoming) {
      final until = nominationStart.difference(now);
      return _formatDuration(until, 'until nominations');
    }

    if (isNominationOpen) {
      final remaining = nominationEnd.difference(now);
      return _formatDuration(remaining, 'left for nominations');
    }

    if (hasNominationEnded && !hasVotingStarted) {
      final until = votingStart.difference(now);
      return _formatDuration(until, 'until voting');
    }

    if (isVotingOpen) {
      final remaining = votingEnd.difference(now);
      return _formatDuration(remaining, 'left for voting');
    }

    return 'Closed';
  }

  String _formatDuration(Duration duration, String suffix) {
    if (duration.isNegative) return 'Ended';

    if (duration.inDays > 0) {
      return '${duration.inDays}d $suffix';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h $suffix';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m $suffix';
    } else {
      return 'Less than 1m $suffix';
    }
  }

  // Debug helper
  void printDebugInfo() {
    final now = DateTime.now();
    print('=== Position: $positionName ===');
    print('isActive: $isActive');
    print('Now: $now');
    print('Nomination: $nominationStart - $nominationEnd');
    print('Voting: $votingStart - $votingEnd');
    print('isNominationOpen: $isNominationOpen');
    print('isVotingOpen: $isVotingOpen');
    print('Status: $statusText');
    print('==============================');
  }
}
