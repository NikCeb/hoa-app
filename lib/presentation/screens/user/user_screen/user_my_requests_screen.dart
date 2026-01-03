import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/request_repository.dart';
import '../../../../data/repositories/incident_repository.dart';
import '../help_request/user_create_help_request_screen.dart';
import '../incident_report/user_create_incident_report_screen.dart';
import '../help_request/user_my_help_request_screen.dart';
import '../incident_report/user_my_incident_report_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({Key? key}) : super(key: key);

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  String _activeView = 'help'; // 'help' or 'incident'

  final _helpRepository = RequestRepository();
  final _incidentRepository = IncidentRepository();

  int _helpRequestCount = 0;
  int _incidentReportCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    // Listen to help requests
    _helpRepository.getUserRequestsByStatus().listen((data) {
      if (mounted) {
        setState(() {
          _helpRequestCount = data['stats']['total'] ?? 0;
        });
      }
    });

    // Listen to incident reports
    _incidentRepository.getUserReports().listen((reports) {
      if (mounted) {
        setState(() {
          _incidentReportCount = reports.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'My Requests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Compact Navigation Cards
          Container(
            color: AppColors.primaryBlue,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavigationCard(
                    title: 'Help Requests',
                    icon: Icons.volunteer_activism,
                    color: Colors.orange,
                    viewKey: 'help',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNavigationCard(
                    title: 'Incident Reports',
                    icon: Icons.report_problem,
                    color: Colors.red,
                    viewKey: 'incident',
                  ),
                ),
              ],
            ),
          ),

          // Content (switches based on active view)
          Expanded(
            child: _activeView == 'help'
                ? const MyHelpRequestsScreen()
                : const MyIncidentReportScreen(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_activeView == 'help') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateHelpRequestScreen(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateIncidentReportScreen(),
              ),
            );
          }
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add),
        label: Text(_activeView == 'help' ? 'New Request' : 'New Report'),
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required IconData icon,
    required Color color,
    required String viewKey,
  }) {
    final isActive = _activeView == viewKey;

    return Card(
      elevation: isActive ? 6 : 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: Colors.white, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _activeView = viewKey;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isActive
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : color.withOpacity(0.15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isActive ? Colors.white : color,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
