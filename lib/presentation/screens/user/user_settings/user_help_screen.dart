import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UserHelpScreen extends StatelessWidget {
  const UserHelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contact Admin Section
          _buildContactAdminCard(context),
          const SizedBox(height: 24),

          // FAQs Header
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // FAQ Items
          _buildFAQItem(
            question: 'How do I make a payment?',
            answer:
                'Go to the Payments tab, select a payment category, enter the amount and reference number, upload your proof of payment, and submit. Your payment will be reviewed by the admin.',
          ),
          _buildFAQItem(
            question: 'How do I request help from neighbors?',
            answer:
                'Navigate to My Requests tab, tap the + button, fill in the details of what you need help with, and submit. Other residents can offer to help you.',
          ),
          _buildFAQItem(
            question: 'How do I report an incident?',
            answer:
                'Go to My Requests tab, switch to Incident Reports, tap the + button, describe the incident, add photos if needed, and submit. The admin will review your report.',
          ),
          _buildFAQItem(
            question: 'How do I vote in elections?',
            answer:
                'When an election is active, go to Profile → Elections, select the active election, and tap "Cast Your Vote". Select your preferred candidates for each position and submit.',
          ),
          _buildFAQItem(
            question: 'Can I nominate someone for election?',
            answer:
                'Yes! Go to Elections, select an active/upcoming election, and tap "Nominate". Choose the position and the resident you want to nominate.',
          ),
          _buildFAQItem(
            question: 'How do I sell items in the Marketplace?',
            answer:
                'Go to Home → Market tab, tap "My Listings", then tap the + button. Add photos, description, price, and other details. Your listing will be visible to all residents.',
          ),
          _buildFAQItem(
            question: 'How do I update my profile information?',
            answer:
                'Go to Profile tab, tap Settings (gear icon), and you can update your email, phone number, or change your password.',
          ),
          _buildFAQItem(
            question: 'What should I do if I forgot my password?',
            answer:
                'On the login screen, tap "Forgot Password?" and enter your email. You\'ll receive a password reset link via email.',
          ),

          const SizedBox(height: 24),

          // Still Need Help Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2563EB).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 48,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Still need help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact the HOA admin directly using the information above',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAdminCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Get direct assistance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email
            _buildContactRow(
              context,
              icon: Icons.email,
              label: 'Email',
              value: 'admin@hoabarangay.com',
              onTap: () {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'admin@hoabarangay.com',
                  query: 'subject=HOA Support Request',
                );
                _launchURL(emailUri.toString());
              },
            ),
            const SizedBox(height: 12),

            // Phone
            _buildContactRow(
              context,
              icon: Icons.phone,
              label: 'Phone',
              value: '+63 912 345 6789',
              onTap: () {
                final Uri phoneUri = Uri(scheme: 'tel', path: '+639123456789');
                _launchURL(phoneUri.toString());
              },
            ),
            const SizedBox(height: 12),

            // Office Hours
            _buildContactRow(
              context,
              icon: Icons.access_time,
              label: 'Office Hours',
              value: 'Mon-Fri, 9AM-5PM',
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.help_outline,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
