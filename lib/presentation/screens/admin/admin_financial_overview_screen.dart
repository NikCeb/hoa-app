import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminFinancialOverviewScreen extends StatefulWidget {
  const AdminFinancialOverviewScreen({Key? key}) : super(key: key);

  @override
  State<AdminFinancialOverviewScreen> createState() =>
      _AdminFinancialOverviewScreenState();
}

class _AdminFinancialOverviewScreenState
    extends State<AdminFinancialOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial & Asset Oversight',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Monitor HOA fees and payments',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh data
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Financial Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.account_balance_wallet,
                      iconColor: const Color(0xFF059669),
                      value: '₱ 250,000',
                      label: 'Expected Collectibles',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.warning_amber,
                      iconColor: const Color(0xFFDC2626),
                      value: '₱ 27,500',
                      label: 'Past Due Balance',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.pending_actions,
                      iconColor: const Color(0xFFEAB308),
                      value: '12',
                      label: 'Verification Pending',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.trending_up,
                      iconColor: const Color(0xFF2563EB),
                      value: '89.0%',
                      label: 'Mission Complete Score',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Subdivision Financial Heatmap
              _buildSectionHeader('Subdivision Financial Heatmap'),
              const SizedBox(height: 12),
              _buildLegend(),
              const SizedBox(height: 12),
              _buildHeatmap(),
              const SizedBox(height: 24),

              // Top 10 Delinquent Units
              _buildSectionHeader('Top 10 Delinquent Units'),
              const SizedBox(height: 12),
              _buildDelinquentTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Colors.green, 'Paid'),
          _buildLegendItem(Colors.orange, 'Part Due'),
          _buildLegendItem(Colors.red, 'Delinquent'),
          _buildLegendItem(Colors.grey[300]!, 'Available'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHeatmap() {
    // Sample data - in real app, fetch from Firestore
    final lots = [
      {'lot': 'Lot 1-A', 'resident': 'Juan Dela Cruz', 'status': 'paid'},
      {'lot': 'Lot 1-B', 'resident': 'Maria Santos', 'status': 'paid'},
      {'lot': 'Lot 2-A', 'resident': 'Pedro Reyes', 'status': 'partDue'},
      {'lot': 'Lot 2-B', 'resident': 'Rosa Mendoza', 'status': 'paid'},
      {'lot': 'Lot 3-A', 'resident': 'Luis Garcia', 'status': 'delinquent'},
      {'lot': 'Lot 3-B', 'resident': 'Anna Cruz', 'status': 'partDue'},
      {'lot': 'Lot 4-A', 'resident': 'Roberto Tan', 'status': 'paid'},
      {'lot': 'Lot 4-B', 'resident': 'Carmen Flores', 'status': 'delinquent'},
      {'lot': 'Lot 5-A', 'resident': 'Miguel Santos', 'status': 'paid'},
      {'lot': 'Lot 5-B', 'resident': 'Lola Carmen', 'status': 'partDue'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: lots.length,
        itemBuilder: (context, index) {
          final lot = lots[index];
          return _buildLotCard(lot);
        },
      ),
    );
  }

  Widget _buildLotCard(Map<String, dynamic> lot) {
    Color bgColor;
    switch (lot['status']) {
      case 'paid':
        bgColor = Colors.green;
        break;
      case 'partDue':
        bgColor = Colors.orange;
        break;
      case 'delinquent':
        bgColor = Colors.red;
        break;
      default:
        bgColor = Colors.grey[300]!;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            lot['lot'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lot['resident'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDelinquentTable() {
    // Sample delinquent data
    final delinquents = [
      {
        'lot': 'Lot 4-B',
        'name': 'Carmen Flores',
        'status': 'Delinquent',
        'balance': 10000
      },
      {
        'lot': 'Lot 3-A',
        'name': 'Luis Garcia',
        'status': 'Delinquent',
        'balance': 7500
      },
      {
        'lot': 'Lot 3-B',
        'name': 'Anna Cruz',
        'status': 'Part Due',
        'balance': 5000
      },
      {
        'lot': 'Lot 2-A',
        'name': 'Pedro Reyes',
        'status': 'Part Due',
        'balance': 2500
      },
      {
        'lot': 'Lot 5-B',
        'name': 'Lola Carmen',
        'status': 'Part Due',
        'balance': 2500
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: delinquents.map((item) {
          return _buildDelinquentItem(
            lotNumber: item['lot'] as String,
            residentName: item['name'] as String,
            status: item['status'] as String,
            balance: item['balance'] as int,
            isLast: item == delinquents.last,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDelinquentItem({
    required String lotNumber,
    required String residentName,
    required String status,
    required int balance,
    required bool isLast,
  }) {
    final statusColor = status == 'Delinquent' ? Colors.red : Colors.orange;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lotNumber,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      residentName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₱ ${balance.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.email_outlined, size: 20),
                onPressed: () {
                  // TODO: Send reminder
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reminder sent to $residentName'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }
}
