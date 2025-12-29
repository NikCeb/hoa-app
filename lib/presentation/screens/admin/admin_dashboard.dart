import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import 'admin_financial_overview_screen.dart';
import 'admin_verification_queue_screen.dart';
import 'admin_governance_screen.dart';
import 'admin_help_requests_screen.dart';
import 'admin_incident_reports_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A), // Dark blue
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Admin Portal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E3A8A),
                      const Color(0xFF2563EB),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 80, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOA Connect',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Administrative Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Section
                  _buildQuickStats(),
                  const SizedBox(height: 24),

                  // Main Management Sections
                  Text(
                    'Management Sections',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Financial Overview
                  _buildSectionCard(
                    context,
                    icon: Icons.account_balance_wallet,
                    iconColor: const Color(0xFF059669),
                    title: 'Financial Overview',
                    subtitle: 'Monitor HOA fees and payments',
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF059669).withOpacity(0.1),
                        const Color(0xFF10B981).withOpacity(0.05),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminFinancialOverviewScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Verification Queue
                  _buildSectionCard(
                    context,
                    icon: Icons.verified_user,
                    iconColor: const Color(0xFF2563EB),
                    title: 'Verification Queue',
                    subtitle: 'Review user registrations',
                    badge: '3',
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2563EB).withOpacity(0.1),
                        const Color(0xFF3B82F6).withOpacity(0.05),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminVerificationQueueScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Governance & Reports
                  _buildSectionCard(
                    context,
                    icon: Icons.gavel,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Governance & Reports',
                    subtitle: 'User reports and elections',
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7C3AED).withOpacity(0.1),
                        const Color(0xFF8B5CF6).withOpacity(0.05),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminGovernanceScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Community Management
                  Text(
                    'Community Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Help Requests
                  _buildSectionCard(
                    context,
                    icon: Icons.help_outline,
                    iconColor: const Color(0xFFEAB308),
                    title: 'Help Requests',
                    subtitle: 'Manage community requests',
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFEAB308).withOpacity(0.1),
                        const Color(0xFFFBBF24).withOpacity(0.05),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminHelpRequestsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Incident Reports
                  _buildSectionCard(
                    context,
                    icon: Icons.warning_amber,
                    iconColor: const Color(0xFFDC2626),
                    title: 'Incident Reports',
                    subtitle: 'Review and resolve incidents',
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFDC2626).withOpacity(0.1),
                        const Color(0xFFEF4444).withOpacity(0.05),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminIncidentReportsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('12', 'Pending', Colors.orange),
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Expanded(
                child: _buildStatItem('5', 'Reports', Colors.red),
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Expanded(
                child: _buildStatItem('89%', 'Paid', Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
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

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
