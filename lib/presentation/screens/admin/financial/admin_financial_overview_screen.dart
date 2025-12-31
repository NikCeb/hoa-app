import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../../data/repositories/financial_repository.dart';
import '../heat_map/admin_full_heatmap_screen.dart';
import 'admin_fee_definition_screen.dart';
import 'admin_bill_generation_screen.dart';

class AdminFinancialOverviewScreen extends StatefulWidget {
  const AdminFinancialOverviewScreen({Key? key}) : super(key: key);

  @override
  State<AdminFinancialOverviewScreen> createState() =>
      _AdminFinancialOverviewScreenState();
}

class _AdminFinancialOverviewScreenState
    extends State<AdminFinancialOverviewScreen> {
  final FinancialRepository _repository = FinancialRepository();
  bool _isLoading = true;
  FinancialSummary? _summary;
  Map<String, LotPaymentStatus> _lotStatuses = {};

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
      final summary = await _repository.getFinancialSummary();
      final lotStatuses = await _repository.getLotPaymentStatuses();

      setState(() {
        _summary = summary;
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ACTION BUTTONS (Fee Definition & Bill Generation)
                    _buildActionButtons(),
                    const SizedBox(height: 16),

                    // Financial Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.account_balance_wallet,
                            iconColor: const Color(0xFF059669),
                            value: _summary?.formattedExpected ?? '₱0',
                            label: 'Expected Collectibles',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.warning_amber,
                            iconColor: const Color(0xFFDC2626),
                            value: _summary?.formattedOverdue ?? '₱0',
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
                            value: _summary?.pendingCount.toString() ?? '0',
                            label: 'Verification Pending',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.trending_up,
                            iconColor: const Color(0xFF2563EB),
                            value: _summary?.formattedCompletionRate ?? '0%',
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
                    const SizedBox(height: 16),

                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AdminFullHeatmapScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.fullscreen, size: 20),
                        label: const Text(
                          'View Full Heatmap',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          side: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

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

  // ============================================
  // ACTION BUTTONS (NEW!)
  // ============================================
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Fee Definition Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminFeeDefinitionScreen(),
                ),
              );
              // Refresh data when returning
              _loadData();
            },
            icon: const Icon(Icons.settings, size: 20),
            label: const Text(
              'Fee Definition',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Bill Generation Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminBillGenerationScreen(),
                ),
              );
              // Refresh data when returning
              _loadData();
            },
            icon: const Icon(Icons.receipt_long, size: 20),
            label: const Text(
              'Generate Bills',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
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
    // Get real lot data from _lotStatuses
    final lots = [
      {'lot': 'Lot 1-A', 'resident': 'Juan Dela Cruz'},
      {'lot': 'Lot 1-B', 'resident': 'Maria Santos'},
      {'lot': 'Lot 2-A', 'resident': 'Pedro Reyes'},
      {'lot': 'Lot 2-B', 'resident': 'Rosa Mendoza'},
      {'lot': 'Lot 3-A', 'resident': 'Luis Garcia'},
      {'lot': 'Lot 3-B', 'resident': 'Anna Cruz'},
      {'lot': 'Lot 4-A', 'resident': 'Roberto Tan'},
      {'lot': 'Lot 4-B', 'resident': 'Carmen Flores'},
      {'lot': 'Lot 5-A', 'resident': 'Miguel Santos'},
      {'lot': 'Lot 5-B', 'resident': 'Lola Carmen'},
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
          final lotNumber = lot['lot'] as String;
          final status = _lotStatuses[lotNumber] ?? LotPaymentStatus.available;
          return _buildLotCard(lot, status);
        },
      ),
    );
  }

  Widget _buildLotCard(Map<String, dynamic> lot, LotPaymentStatus status) {
    Color bgColor;
    switch (status) {
      case LotPaymentStatus.paid:
        bgColor = Colors.green;
        break;
      case LotPaymentStatus.partDue:
        bgColor = Colors.orange;
        break;
      case LotPaymentStatus.delinquent:
        bgColor = Colors.red;
        break;
      case LotPaymentStatus.available:
        bgColor = Colors.grey[300]!;
        break;
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
            lot['resident'] ?? '',
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
    // Sample delinquent data - in production, query from payments collection
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
