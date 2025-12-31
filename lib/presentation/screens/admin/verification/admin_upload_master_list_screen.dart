import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUploadMasterListScreen extends StatefulWidget {
  const AdminUploadMasterListScreen({Key? key}) : super(key: key);

  @override
  State<AdminUploadMasterListScreen> createState() =>
      _AdminUploadMasterListScreenState();
}

class _AdminUploadMasterListScreenState
    extends State<AdminUploadMasterListScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Master List',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Instructions Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'CSV Upload Instructions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your CSV file should have these columns:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildInstructionRow('1', 'name', 'Full name of resident'),
                  _buildInstructionRow('2', 'email', 'Email address'),
                  _buildInstructionRow('3', 'phone', 'Phone number (optional)'),
                  _buildInstructionRow('4', 'lotNumber', 'Lot/Block number'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'name,email,phone,lotNumber\n'
                      'Maria Santos,maria@example.com,+63 912 345 6789,Block 2 Lot 15',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Upload Button
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7C3AED),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: InkWell(
              onTap: _isUploading ? null : _pickCSV,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 64,
                    color: _isUploading ? Colors.grey : const Color(0xFF7C3AED),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isUploading ? 'Uploading...' : 'Tap to Select CSV File',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          _isUploading ? Colors.grey : const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Maximum 100 residents per upload',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Important Notes
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Important Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildNoteRow(
                      '• All uploaded residents will be auto-verified'),
                  _buildNoteRow(
                      '• Duplicate emails will be skipped automatically'),
                  _buildNoteRow(
                      '• Firebase Auth accounts will NOT be created (add manually if needed)'),
                  _buildNoteRow(
                      '• You can download template CSV from settings'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(
      String number, String column, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: column,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' - '),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteRow(String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        note,
        style: TextStyle(
          fontSize: 13,
          color: Colors.orange[900],
        ),
      ),
    );
  }

  Future<void> _pickCSV() async {
    // TODO: Implement file picker
    // For now, show a message that feature requires file_picker package

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'CSV upload requires file_picker package.\n'
          'Add to pubspec.yaml:\n'
          'dependencies:\n'
          '  file_picker: ^8.0.0+1\n'
          '  csv: ^6.0.0',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    // ACTUAL IMPLEMENTATION (uncomment after adding packages):
    /*
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() => _isUploading = true);
        
        final bytes = result.files.first.bytes;
        final csvString = String.fromCharCodes(bytes!);
        
        List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
        
        // Skip header row
        final residents = csvData.skip(1).toList();
        
        // Batch write to Firestore
        final batch = FirebaseFirestore.instance.batch();
        int count = 0;
        
        for (var row in residents) {
          if (row.length >= 4) {
            final docRef = FirebaseFirestore.instance.collection('users').doc();
            batch.set(docRef, {
              'name': row[0].toString(),
              'email': row[1].toString(),
              'phone': row.length > 2 ? row[2].toString() : '',
              'lotNumber': row[3].toString(),
              'role': 'user',
              'isVerified': true,
              'tulongCount': 0,
              'createdAt': FieldValue.serverTimestamp(),
            });
            count++;
          }
        }
        
        await batch.commit();
        
        setState(() => _isUploading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully uploaded $count residents'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    */
  }
}
