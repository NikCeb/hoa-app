import 'package:flutter/material.dart';
import '../../../../data/repositories/financial_repository.dart';

/// Admin Full Heatmap Screen - Detailed view of all lot payment statuses
///
/// Features:
/// - Large grid showing all lots
/// - Color-coded by payment status
/// - Tap lot to see details
/// - Legend explaining colors
class AdminFullHeatmapScreen extends StatefulWidget {
  const AdminFullHeatmapScreen({super.key});

  @override
  State<AdminFullHeatmapScreen> createState() => _AdminFullHeatmapScreenState();
}

class _AdminFullHeatmapScreenState extends State<AdminFullHeatmapScreen> {
  final FinancialRepository _repository = FinancialRepository();
  bool _isLoading = true;
  Map<String, LotPaymentStatus> _lotStatuses = {};

  // Sample lot data - in production, fetch from master_residents
  final Map<String, String> _lotResidents = {
    'Lot 1-A': 'Juan Dela Cruz',
    'Lot 1-B': 'Maria Santos',
    'Lot 2-A': 'Pedro Reyes',
    'Lot 2-B': 'Rosa Mendoza',
    'Lot 3-A': 'Luis Garcia',
    'Lot 3-B': 'Anna Cruz',
    'Lot 4-A': 'Roberto Tan',
    'Lot 4-B': 'Carmen Flores',
    'Lot 5-A': 'Miguel Santos',
    'Lot 5-B': 'Lola Carmen',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lotStatuses = await _repository.getLotPaymentStatuses();

      setState(() {
        _lotStatuses = lotStatuses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text(
          'Subdivision Financial Heatmap',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Legend
                    _buildLegend(),
                    const SizedBox(height: 24),

                    // Stats Summary
                    _buildStatsSummary(),
                    const SizedBox(height: 24),

                    // Full Heatmap Grid
                    _buildFullHeatmapGrid(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Status Legend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildLegendItem(
                color: Colors.green[500]!,
                label: 'Paid',
                description: 'All bills paid',
              ),
              _buildLegendItem(
                color: Colors.orange[500]!,
                label: 'Part Due',
                description: 'Some bills owed',
              ),
              _buildLegendItem(
                color: Colors.red[500]!,
                label: 'Delinquent',
                description: 'Overdue payments',
              ),
              _buildLegendItem(
                color: Colors.grey[300]!,
                label: 'Available',
                description: 'No resident',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String description,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSummary() {
    int paidCount = 0;
    int partDueCount = 0;
    int delinquentCount = 0;
    int availableCount = 0;

    _lotStatuses.forEach((lot, status) {
      switch (status) {
        case LotPaymentStatus.paid:
          paidCount++;
          break;
        case LotPaymentStatus.partDue:
          partDueCount++;
          break;
        case LotPaymentStatus.delinquent:
          delinquentCount++;
          break;
        case LotPaymentStatus.available:
          availableCount++;
          break;
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Paid', paidCount, Colors.green),
              _buildStatColumn('Part Due', partDueCount, Colors.orange),
              _buildStatColumn('Delinquent', delinquentCount, Colors.red),
              _buildStatColumn('Available', availableCount, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFullHeatmapGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Lots',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Grid of lots (5 rows x 2 columns)
          ...List.generate(5, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: List.generate(2, (col) {
                  final lotNumber =
                      'Lot ${row + 1}-${String.fromCharCode(65 + col)}';
                  final status =
                      _lotStatuses[lotNumber] ?? LotPaymentStatus.available;
                  final resident = _lotResidents[lotNumber];

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: col == 0 ? 6 : 0,
                        left: col == 1 ? 6 : 0,
                      ),
                      child: _buildLotCard(lotNumber, resident, status),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLotCard(
      String lotNumber, String? resident, LotPaymentStatus status) {
    Color bgColor;
    String statusText;

    switch (status) {
      case LotPaymentStatus.paid:
        bgColor = Colors.green[500]!;
        statusText = 'Paid';
        break;
      case LotPaymentStatus.partDue:
        bgColor = Colors.orange[500]!;
        statusText = 'Part Due';
        break;
      case LotPaymentStatus.delinquent:
        bgColor = Colors.red[500]!;
        statusText = 'Delinquent';
        break;
      case LotPaymentStatus.available:
        bgColor = Colors.grey[300]!;
        statusText = 'Available';
        break;
    }

    return InkWell(
      onTap: resident != null
          ? () => _showLotDetails(lotNumber, resident, status)
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lotNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (resident != null) ...[
              Text(
                resident,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              Text(
                statusText,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLotDetails(
      String lotNumber, String resident, LotPaymentStatus status) {
    String statusText;
    Color statusColor;

    switch (status) {
      case LotPaymentStatus.paid:
        statusText = 'All bills paid';
        statusColor = Colors.green;
        break;
      case LotPaymentStatus.partDue:
        statusText = 'Some bills owed';
        statusColor = Colors.orange;
        break;
      case LotPaymentStatus.delinquent:
        statusText = 'Has overdue payments';
        statusColor = Colors.red;
        break;
      case LotPaymentStatus.available:
        statusText = 'No resident';
        statusColor = Colors.grey;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lotNumber),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resident,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
