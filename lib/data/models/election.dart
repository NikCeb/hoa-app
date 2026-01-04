import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ElectionStatus { upcoming, active, closed }

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
  final bool isFinalized;
  final DateTime? finalizedAt;
  final int? totalVotesCast;

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
    this.isFinalized = false,
    this.finalizedAt,
    this.totalVotesCast,
  });

  factory Election.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return fallback;
    }

    final timeStart = parseDate(data['timeStart'], DateTime.now());
    final timeEnd =
        parseDate(data['timeEnd'], DateTime.now().add(const Duration(days: 7)));
    final now = DateTime.now();

    // Compute status based on dates
    ElectionStatus computedStatus;
    if (now.isBefore(timeStart)) {
      computedStatus = ElectionStatus.upcoming;
    } else if (now.isAfter(timeEnd)) {
      computedStatus = ElectionStatus.closed;
    } else {
      computedStatus = ElectionStatus.active;
    }

    // Override if explicitly finalized or inactive
    if (data['isFinalized'] == true || data['isActive'] == false) {
      computedStatus = ElectionStatus.closed;
    }

    return Election(
      id: doc.id,
      electionName: data['electionName'] ?? '',
      timeStart: timeStart,
      timeEnd: timeEnd,
      isActive: data['isActive'] ?? true,
      candidateResults:
          Map<String, dynamic>.from(data['candidateResults'] ?? {}),
      totalVerifiedVoters: data['totalVerifiedVoters'] ?? 0,
      status: computedStatus,
      createdAt: parseDate(data['createdAt'], DateTime.now()),
      isFinalized: data['isFinalized'] ?? false,
      finalizedAt: data['finalizedAt'] != null
          ? parseDate(data['finalizedAt'], DateTime.now())
          : null,
      totalVotesCast: data['totalVotesCast'],
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
      'createdAt': Timestamp.fromDate(createdAt),
      'isFinalized': isFinalized,
      if (finalizedAt != null) 'finalizedAt': Timestamp.fromDate(finalizedAt!),
      if (totalVotesCast != null) 'totalVotesCast': totalVotesCast,
    };
  }

  // Computed properties
  bool get hasStarted => DateTime.now().isAfter(timeStart);
  bool get hasEnded => DateTime.now().isAfter(timeEnd);
  bool get isOngoing => hasStarted && !hasEnded;

  String get statusText {
    if (isFinalized) return 'Finalized';
    switch (status) {
      case ElectionStatus.upcoming:
        return 'Upcoming';
      case ElectionStatus.active:
        return 'Active';
      case ElectionStatus.closed:
        return 'Closed';
    }
  }

  Color get statusColor {
    if (isFinalized) return const Color(0xFF10B981); // Green
    switch (status) {
      case ElectionStatus.upcoming:
        return const Color(0xFFF59E0B); // Orange
      case ElectionStatus.active:
        return const Color(0xFF3B82F6); // Blue
      case ElectionStatus.closed:
        return const Color(0xFF6B7280); // Grey
    }
  }

  String get timeRemainingText {
    final now = DateTime.now();

    if (!hasStarted) {
      final until = timeStart.difference(now);
      return _formatDuration(until, 'until start');
    }

    if (isOngoing) {
      final remaining = timeEnd.difference(now);
      return _formatDuration(remaining, 'remaining');
    }

    return 'Ended';
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

  // Copy with method for updates
  Election copyWith({
    String? id,
    String? electionName,
    DateTime? timeStart,
    DateTime? timeEnd,
    bool? isActive,
    Map<String, dynamic>? candidateResults,
    int? totalVerifiedVoters,
    ElectionStatus? status,
    DateTime? createdAt,
    bool? isFinalized,
    DateTime? finalizedAt,
    int? totalVotesCast,
  }) {
    return Election(
      id: id ?? this.id,
      electionName: electionName ?? this.electionName,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      isActive: isActive ?? this.isActive,
      candidateResults: candidateResults ?? this.candidateResults,
      totalVerifiedVoters: totalVerifiedVoters ?? this.totalVerifiedVoters,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isFinalized: isFinalized ?? this.isFinalized,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      totalVotesCast: totalVotesCast ?? this.totalVotesCast,
    );
  }
}
