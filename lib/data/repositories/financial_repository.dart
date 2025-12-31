import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_category.dart';
import '../models/payment.dart';

/// Financial Repository - Handles all payment and billing operations
class FinancialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // PAYMENT CATEGORIES (Fee Definition)
  // ============================================================

  /// Get all payment categories
  Stream<List<PaymentCategory>> getPaymentCategories() {
    return _firestore
        .collection('payment_categories')
        .orderBy('categoryName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentCategory.fromFirestore(doc))
            .toList());
  }

  /// Get active payment categories only
  Stream<List<PaymentCategory>> getActiveCategories() {
    return _firestore
        .collection('payment_categories')
        .where('isActive', isEqualTo: true)
        .orderBy('categoryName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentCategory.fromFirestore(doc))
            .toList());
  }

  /// Create new payment category
  Future<void> createPaymentCategory(PaymentCategory category) async {
    await _firestore
        .collection('payment_categories')
        .add(category.toFirestore());
  }

  /// Update payment category
  Future<void> updatePaymentCategory(
      String categoryId, PaymentCategory category) async {
    await _firestore
        .collection('payment_categories')
        .doc(categoryId)
        .update(category.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  /// Delete payment category (soft delete - set inactive)
  Future<void> deletePaymentCategory(String categoryId) async {
    await _firestore.collection('payment_categories').doc(categoryId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // BILL GENERATION
  // ============================================================

  /// Generate bills for all occupied lots for a given billing period
  ///
  /// This should be called at the start of each billing cycle (e.g., monthly)
  ///
  /// Steps:
  /// 1. Get all active payment categories
  /// 2. Get all occupied lots from master_residents
  /// 3. For each lot + category, create a payment document
  Future<int> generateBills(String billingPeriod) async {
    int billsCreated = 0;

    try {
      // Get active recurring categories
      final categoriesSnapshot = await _firestore
          .collection('payment_categories')
          .where('isActive', isEqualTo: true)
          .where('isRecurring', isEqualTo: true)
          .get();

      if (categoriesSnapshot.docs.isEmpty) {
        throw Exception('No active payment categories found');
      }

      // Get occupied lots
      final residentsSnapshot = await _firestore
          .collection('master_residents')
          .where('status', isEqualTo: 'occupied')
          .get();

      if (residentsSnapshot.docs.isEmpty) {
        throw Exception('No occupied lots found');
      }

      // Use batch for efficient writes
      final batch = _firestore.batch();

      // For each resident and category, create a payment
      for (final residentDoc in residentsSnapshot.docs) {
        final residentData = residentDoc.data();
        final lotId = residentDoc.id;
        final residentId = residentData['residentId'] ?? '';
        final residentName =
            '${residentData['firstName'] ?? ''} ${residentData['lastName'] ?? ''}'
                .trim();
        final lotNumber = residentData['lotNumber'] ?? '';

        for (final categoryDoc in categoriesSnapshot.docs) {
          final category = PaymentCategory.fromFirestore(categoryDoc);

          // Check if bill already exists for this period
          final existingBill = await _firestore
              .collection('payments')
              .where('lotId', isEqualTo: lotId)
              .where('categoryId', isEqualTo: category.id)
              .where('billingPeriod', isEqualTo: billingPeriod)
              .get();

          if (existingBill.docs.isEmpty) {
            // Create new payment
            final payment = Payment(
              id: '', // Will be assigned by Firestore
              lotId: lotId,
              residentId: residentId,
              residentName: residentName,
              lotNumber: lotNumber,
              categoryId: category.id,
              categoryName: category.categoryName,
              amount: category.defaultFee,
              status: PaymentStatus.owed,
              dateDue: _calculateDueDate(category.dueDayOfMonth),
              createdAt: DateTime.now(),
              billingPeriod: billingPeriod,
            );

            // Add to batch
            final docRef = _firestore.collection('payments').doc();
            batch.set(docRef, payment.toFirestore());
            billsCreated++;
          }
        }
      }

      // Commit batch
      await batch.commit();
      return billsCreated;
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate due date based on due day of month
  DateTime _calculateDueDate(int dueDayOfMonth) {
    final now = DateTime.now();
    // Use current month if we haven't passed the due day, otherwise next month
    final month = now.day <= dueDayOfMonth ? now.month : now.month + 1;
    final year = month > 12 ? now.year + 1 : now.year;
    final adjustedMonth = month > 12 ? 1 : month;

    return DateTime(year, adjustedMonth, dueDayOfMonth);
  }

  /// Get current billing period (format: YYYY-MM)
  String getCurrentBillingPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // PAYMENT QUERIES
  // ============================================================

  /// Get all payments
  Stream<List<Payment>> getAllPayments() {
    return _firestore
        .collection('payments')
        .orderBy('dateDue', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  /// Get payments by status
  Stream<List<Payment>> getPaymentsByStatus(PaymentStatus status) {
    return _firestore
        .collection('payments')
        .where('status', isEqualTo: status.name)
        .orderBy('dateDue')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  /// Get payments for a specific resident
  Stream<List<Payment>> getResidentPayments(String residentId) {
    return _firestore
        .collection('payments')
        .where('residentId', isEqualTo: residentId)
        .orderBy('dateDue', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  /// Get payments for a specific lot
  Stream<List<Payment>> getLotPayments(String lotId) {
    return _firestore
        .collection('payments')
        .where('lotId', isEqualTo: lotId)
        .orderBy('dateDue', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList());
  }

  /// Get payments for a billing period
  Future<List<Payment>> getPaymentsByPeriod(String billingPeriod) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('billingPeriod', isEqualTo: billingPeriod)
        .orderBy('lotNumber')
        .get();

    return snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();
  }

  // ============================================================
  // PAYMENT UPDATES
  // ============================================================

  /// Update payment status to PENDING_REVIEW (when resident submits proof)
  Future<void> submitPaymentProof(
    String paymentId,
    String proofRef,
    String proofUrl,
  ) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': PaymentStatus.pendingReview.name,
      'proofRef': proofRef,
      'proofUrl': proofUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Approve payment (admin verifies proof)
  Future<void> approvePayment(String paymentId, {String? notes}) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': PaymentStatus.paid.name,
      'datePaid': FieldValue.serverTimestamp(),
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject payment proof (admin rejects proof)
  Future<void> rejectPayment(String paymentId, String notes) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': PaymentStatus.owed.name,
      'proofRef': null,
      'proofUrl': null,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // FINANCIAL STATISTICS
  // ============================================================

  /// Get financial summary
  Future<FinancialSummary> getFinancialSummary() async {
    final paymentsSnapshot = await _firestore.collection('payments').get();

    double totalExpected = 0;
    double totalPaid = 0;
    double totalPending = 0;
    double totalOverdue = 0;
    int pendingCount = 0;

    for (final doc in paymentsSnapshot.docs) {
      final payment = Payment.fromFirestore(doc);
      totalExpected += payment.amount;

      switch (payment.status) {
        case PaymentStatus.paid:
          totalPaid += payment.amount;
          break;
        case PaymentStatus.pendingReview:
          totalPending += payment.amount;
          pendingCount++;
          break;
        case PaymentStatus.owed:
          if (payment.isOverdue) {
            totalOverdue += payment.amount;
          }
          break;
        case PaymentStatus.overdue:
          totalOverdue += payment.amount;
          break;
      }
    }

    final completionRate =
        totalExpected > 0 ? (totalPaid / totalExpected) * 100 : 0.0;

    return FinancialSummary(
      totalExpected: totalExpected,
      totalPaid: totalPaid,
      totalPending: totalPending,
      totalOverdue: totalOverdue,
      pendingCount: pendingCount,
      completionRate: completionRate,
    );
  }

  /// Get lot payment status for heatmap
  Future<Map<String, LotPaymentStatus>> getLotPaymentStatuses() async {
    final lotsSnapshot = await _firestore.collection('master_residents').get();
    final Map<String, LotPaymentStatus> statuses = {};

    for (final lotDoc in lotsSnapshot.docs) {
      final lotData = lotDoc.data();
      final lotNumber = lotData['lotNumber'] ?? '';
      final status = lotData['status'] ?? 'available';

      if (status != 'occupied') {
        statuses[lotNumber] = LotPaymentStatus.available;
        continue;
      }

      // Get payments for this lot
      final paymentsSnapshot = await _firestore
          .collection('payments')
          .where('lotId', isEqualTo: lotDoc.id)
          .get();

      if (paymentsSnapshot.docs.isEmpty) {
        statuses[lotNumber] = LotPaymentStatus.paid;
        continue;
      }

      bool hasOverdue = false;
      bool hasOwed = false;
      bool allPaid = true;

      for (final paymentDoc in paymentsSnapshot.docs) {
        final payment = Payment.fromFirestore(paymentDoc);

        if (payment.status != PaymentStatus.paid) {
          allPaid = false;
        }

        if (payment.isOverdue || payment.status == PaymentStatus.overdue) {
          hasOverdue = true;
        } else if (payment.status == PaymentStatus.owed) {
          hasOwed = true;
        }
      }

      if (allPaid) {
        statuses[lotNumber] = LotPaymentStatus.paid;
      } else if (hasOverdue) {
        statuses[lotNumber] = LotPaymentStatus.delinquent;
      } else if (hasOwed) {
        statuses[lotNumber] = LotPaymentStatus.partDue;
      } else {
        statuses[lotNumber] = LotPaymentStatus.paid;
      }
    }

    return statuses;
  }
}

/// Financial Summary Data
class FinancialSummary {
  final double totalExpected;
  final double totalPaid;
  final double totalPending;
  final double totalOverdue;
  final int pendingCount;
  final double completionRate;

  FinancialSummary({
    required this.totalExpected,
    required this.totalPaid,
    required this.totalPending,
    required this.totalOverdue,
    required this.pendingCount,
    required this.completionRate,
  });

  String get formattedExpected => '₱${totalExpected.toStringAsFixed(0)}';
  String get formattedPaid => '₱${totalPaid.toStringAsFixed(0)}';
  String get formattedPending => '₱${totalPending.toStringAsFixed(0)}';
  String get formattedOverdue => '₱${totalOverdue.toStringAsFixed(0)}';
  String get formattedCompletionRate => '${completionRate.toStringAsFixed(1)}%';
}

/// Lot Payment Status for Heatmap
enum LotPaymentStatus {
  paid, // All payments paid
  partDue, // Some payments owed but not overdue
  delinquent, // Has overdue payments
  available, // Lot not occupied
}
