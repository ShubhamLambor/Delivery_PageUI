// lib/screens/home/kyc_dialog_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/repository/user_repository.dart';

class KycDialogWidget extends StatefulWidget {
  final int userId; // Pass user ID if backend needs it
  final VoidCallback onKycCompleted;

  const KycDialogWidget({
    super.key,
    required this.userId,
    required this.onKycCompleted
  });

  @override
  State<KycDialogWidget> createState() => _KycDialogWidgetState();
}

class _KycDialogWidgetState extends State<KycDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Controllers
  final _vehicleNumberController = TextEditingController();
  final _licenseController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();

  String _selectedVehicleType = 'Bike';

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _licenseController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final repo = UserRepository();

      // Call the specific Delivery Partner API
      await repo.submitDeliveryPartnerKyc(
        userId: widget.userId,
        vehicleType: _selectedVehicleType,
        vehicleNumber: _vehicleNumberController.text.trim(),
        drivingLicense: _licenseController.text.trim(),
        aadharNumber: _aadharController.text.trim(),
        panNumber: _panController.text.trim(),
        bankAccountNumber: _bankAccountController.text.trim(),
        ifscCode: _ifscController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC Submitted Successfully!'), backgroundColor: Colors.green),
      );

      widget.onKycCompleted(); // Callback to parent to close dialog/update state
      Navigator.pop(context); // Close the dialog

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: ${e.toString().replaceAll("Exception:", "")}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent closing by back button
      child: AlertDialog(
        title: const Text('Partner KYC Required'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Welcome! To start receiving orders, please complete your profile details.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedVehicleType,
                    decoration: const InputDecoration(labelText: 'Vehicle Type', border: OutlineInputBorder()),
                    items: ['Bike', 'Scooter', 'Cycle', 'Electric Bike']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedVehicleType = val!),
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(_vehicleNumberController, 'Vehicle Number'),
                  const SizedBox(height: 12),

                  _buildTextField(_licenseController, 'Driving License No.'),
                  const SizedBox(height: 12),

                  _buildTextField(
                      _aadharController, 'Aadhar Number',
                      isNumber: true, maxLength: 12
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(_panController, 'PAN Number'),
                  const SizedBox(height: 12),

                  _buildTextField(_bankAccountController, 'Bank Account No.', isNumber: true),
                  const SizedBox(height: 12),

                  _buildTextField(_ifscController, 'IFSC Code'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          // No Cancel button - Mandatory process
          ElevatedButton(
            onPressed: _loading ? null : _submitKyc,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              minimumSize: const Size(double.infinity, 45),
            ),
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Details', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, int? maxLength}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: [
        if (isNumber) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      validator: (v) => v == null || v.isEmpty ? '$label is required' : null,
    );
  }
}
