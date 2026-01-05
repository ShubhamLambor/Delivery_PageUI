// lib/screens/home/kyc_dialog_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/repository/user_repository.dart';

class KycDialogWidget extends StatefulWidget {
  final VoidCallback onKycCompleted;

  const KycDialogWidget({
    super.key,
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

      // ✅ Call without userId - it's auto-fetched inside the method
      await repo.submitDeliveryPartnerKyc(
        vehicleType: _selectedVehicleType,
        vehicleNumber: _vehicleNumberController.text.trim(),
        drivingLicense: _licenseController.text.trim(),
        aadharNumber: _aadharController.text.trim(),
        panNumber: _panController.text.trim().toUpperCase(),
        bankAccountNumber: _bankAccountController.text.trim(),
        ifscCode: _ifscController.text.trim().toUpperCase(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC Submitted Successfully!'), backgroundColor: Colors.green),
      );

      widget.onKycCompleted();
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Submission failed: ${e.toString().replaceAll("Exception:", "")}'),
            backgroundColor: Colors.red
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
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
                    decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                        border: OutlineInputBorder()
                    ),
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
                      _aadharController,
                      'Aadhar Number',
                      isNumber: true,
                      maxLength: 12,
                      validator: _validateAadhar
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                      _panController,
                      'PAN Number',
                      maxLength: 10,
                      validator: _validatePAN,
                      textCapitalization: TextCapitalization.characters
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                      _bankAccountController,
                      'Bank Account No.',
                      isNumber: true
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                      _ifscController,
                      'IFSC Code',
                      maxLength: 11,
                      validator: _validateIFSC,
                      textCapitalization: TextCapitalization.characters
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: _loading ? null : _submitKyc,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              minimumSize: const Size(double.infinity, 45),
            ),
            child: _loading
                ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2
                )
            )
                : const Text(
                'Submit Details',
                style: TextStyle(color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }

  String? _validateAadhar(String? value) {
    if (value == null || value.isEmpty) return 'Aadhar is required';
    if (value.length != 12) return 'Aadhar must be 12 digits';
    if (!RegExp(r'^\d{12}$').hasMatch(value)) return 'Invalid Aadhar format';
    return null;
  }

  String? _validatePAN(String? value) {
    if (value == null || value.isEmpty) return 'PAN is required';
    final cleaned = value.toUpperCase();
    if (cleaned.length != 10) return 'PAN must be 10 characters';
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(cleaned)) {
      return 'Invalid PAN format';
    }
    return null;
  }

  String? _validateIFSC(String? value) {
    if (value == null || value.isEmpty) return 'IFSC Code is required';
    final cleaned = value.toUpperCase();
    if (cleaned.length != 11) return 'IFSC must be 11 characters';
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(cleaned)) {
      return 'Invalid IFSC format';
    }
    return null;
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool isNumber = false,
        int? maxLength,
        String? Function(String?)? validator,
        TextCapitalization textCapitalization = TextCapitalization.none
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textCapitalization: textCapitalization,
      inputFormatters: [
        if (isNumber) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        counterText: '',
      ),
      validator: validator ?? (v) => v == null || v.isEmpty ? '$label is required' : null,
    );
  }
}
