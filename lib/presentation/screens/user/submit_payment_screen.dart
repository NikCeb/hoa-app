import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SubmitPaymentScreen extends StatefulWidget {
  const SubmitPaymentScreen({Key? key}) : super(key: key);

  @override
  State<SubmitPaymentScreen> createState() => _SubmitPaymentScreenState();
}

class _SubmitPaymentScreenState extends State<SubmitPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedMonth = DateTime.now().month.toString();
  String _selectedYear = DateTime.now().year.toString();
  String _paymentMethod = 'gcash';
  File? _proofImage;
  bool _isSubmitting = false;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  final List<String> _years =
      List.generate(5, (index) => (DateTime.now().year - 2 + index).toString());

  final List<Map<String, String>> _paymentMethods = [
    {'id': 'gcash', 'name': 'GCash', 'icon': '💳'},
    {'id': 'paymaya', 'name': 'PayMaya', 'icon': '💰'},
    {'id': 'bankTransfer', 'name': 'Bank Transfer', 'icon': '🏦'},
    {'id': 'cash', 'name': 'Cash Payment', 'icon': '💵'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Todo: Enable image upload feature with firebase storage
  // Future<void> _pickImage() async {
  //   final picker = ImagePicker();
  //   final pickedFile = await picker.pickImage(
  //     source: ImageSource.gallery,
  //     maxWidth: 1080,
  //     maxHeight: 1920,
  //     imageQuality: 85,
  //   );

  //   if (pickedFile != null) {
  //     setState(() {
  //       _proofImage = File(pickedFile.path);
  //     });
  //   }
  // }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Todo: Enable image upload feature with firebase storage
    // if (_proofImage == null && _paymentMethod != 'cash') {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Please upload payment proof'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    //   return;
    // }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data()!;

      String? proofUrl;
      String? proofRef;

      // Upload proof image if exists
      // TODO : Enable image upload feature with firebase storage
      // if (_proofImage != null) {
      //   final timestamp = DateTime.now().millisecondsSinceEpoch;
      //   final ref = FirebaseStorage.instance
      //       .ref()
      //       .child('payments')
      //       .child(user.uid)
      //       .child('receipt_$timestamp.jpg');

      //   await ref.putFile(_proofImage!);
      //   proofUrl = await ref.getDownloadURL();
      //   proofRef = ref.fullPath;
      // }

      // Create payment document
      await FirebaseFirestore.instance.collection('payments').add({
        'userId': user.uid,
        'userName': userData['name'],
        'lotNumber': userData['lotNumber'] ?? 'N/A',
        'amount': double.parse(_amountController.text),
        'paymentType': 'hoaFees',
        'paymentMethod': _paymentMethod,
        'referenceNumber': _referenceController.text,
        'status': 'pending',
        'proofUrl': proofUrl,
        'proofRef': proofRef,
        'paidAt': FieldValue.serverTimestamp(),
        'verifiedAt': null,
        'verifiedBy': null,
        'notes':
            _notesController.text.isNotEmpty ? _notesController.text : null,
        'month': '${_months[int.parse(_selectedMonth) - 1]} $_selectedYear',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Submit Payment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Submit your payment proof for verification. Admins will review within 24-48 hours.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount
            const Text(
              'Payment Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixText: '₱ ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Month & Year
            const Text(
              'Payment For',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedMonth,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem(
                        value: (index + 1).toString(),
                        child: Text(_months[index]),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _years
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Payment Method
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._paymentMethods.map((method) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _paymentMethod == method['id']
                        ? const Color(0xFF059669)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: RadioListTile<String>(
                  value: method['id']!,
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                  title: Text(
                    '${method['icon']} ${method['name']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  activeColor: const Color(0xFF059669),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),

            // Reference Number
            const Text(
              'Reference Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _referenceController,
              decoration: InputDecoration(
                hintText: 'e.g., GC-2024-12345',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter reference number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Notes (Optional)
            const Text(
              'Notes (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any additional notes...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // TODO: Enable image upload feature with firebase storage
            // Upload Proof?
            // if (_proofImage == null)
            //   InkWell(
            //     onTap: _pickImage,
            //     child: Container(
            //       height: 150,
            //       decoration: BoxDecoration(
            //         color: Colors.grey[100],
            //         borderRadius: BorderRadius.circular(12),
            //         border: Border.all(
            //           color: Colors.grey[300]!,
            //           style: BorderStyle.solid,
            //           width: 2,
            //         ),
            //       ),
            //       child: Column(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           Icon(Icons.cloud_upload,
            //               size: 48, color: Colors.grey[400]),
            //           const SizedBox(height: 8),
            //           Text(
            //             'Tap to upload receipt',
            //             style: TextStyle(
            //               fontSize: 14,
            //               color: Colors.grey[600],
            //             ),
            //           ),
            //           Text(
            //             '(Screenshot or photo)',
            //             style: TextStyle(
            //               fontSize: 12,
            //               color: Colors.grey[500],
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   )
            // else
            //   Stack(
            //     children: [
            //       ClipRRect(
            //         borderRadius: BorderRadius.circular(12),
            //         child: Image.file(
            //           _proofImage!,
            //           height: 200,
            //           width: double.infinity,
            //           fit: BoxFit.cover,
            //         ),
            //       ),
            //       Positioned(
            //         top: 8,
            //         right: 8,
            //         child: IconButton(
            //           onPressed: () {
            //             setState(() {
            //               _proofImage = null;
            //             });
            //           },
            //           icon: const Icon(Icons.close),
            //           style: IconButton.styleFrom(
            //             backgroundColor: Colors.red,
            //             foregroundColor: Colors.white,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
