// lib/screens/kyc/kyc_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/repository/user_repository.dart';

class KYCPage extends StatefulWidget {
  const KYCPage({super.key});

  @override
  State<KYCPage> createState() => _KYCPageState();
}

class _KYCPageState extends State<KYCPage> {
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

  String? _validateAadhar(String? value) {
    if (value == null || value.isEmpty) return 'Aadhaar is required';
    if (value.length != 12) return 'Aadhaar must be 12 digits';
    if (!RegExp(r'^\d{12}$').hasMatch(value)) return 'Invalid Aadhaar format';
    return null;
  }

  String? _validatePAN(String? value) {
    if (value == null || value.isEmpty) return 'PAN is required';
    final cleaned = value.toUpperCase();
    if (cleaned.length != 10) return 'PAN must be 10 characters';
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(cleaned)) {
      return 'Invalid PAN format (e.g., ABCDE1234F)';
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

  Future<void> _handleSubmitKYC() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please correct the errors in the form'),
            backgroundColor: Colors.orange
        ),
      );
      return;
    }

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
        const SnackBar(
            content: Text('KYC Submitted Successfully!'),
            backgroundColor: Colors.green
        ),
      );
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception:", "")}'),
            backgroundColor: Colors.red
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
            'Delivery Partner KYC',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Vehicle Details'),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedVehicleType,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type',
                  prefixIcon: Icon(Icons.two_wheeler, color: Colors.grey[500], size: 22),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300)
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: ['Bike', 'Scooter', 'Cycle', 'Electric Bike']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedVehicleType = val!),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                  'Vehicle Number',
                  _vehicleNumberController,
                  TextInputType.text,
                      (v) => v!.isEmpty ? 'Required' : null,
                  icon: Icons.directions_car,
                  textCapitalization: TextCapitalization.characters
              ),
              const SizedBox(height: 16),

              _buildTextField(
                  'Driving License No.',
                  _licenseController,
                  TextInputType.text,
                      (v) => v!.isEmpty ? 'Required' : null,
                  icon: Icons.credit_card
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('Identity Verification'),
              const SizedBox(height: 16),

              _buildTextField(
                  'Aadhaar Number',
                  _aadharController,
                  TextInputType.number,
                  _validateAadhar,
                  icon: Icons.badge,
                  maxLength: 12
              ),
              const SizedBox(height: 16),

              _buildTextField(
                  'PAN Card Number',
                  _panController,
                  TextInputType.text,
                  _validatePAN,
                  icon: Icons.account_box,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 10
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('Bank Details'),
              const SizedBox(height: 16),

              _buildTextField(
                  'Bank Account Number',
                  _bankAccountController,
                  TextInputType.number,
                      (v) => v!.isEmpty ? 'Required' : null,
                  icon: Icons.account_balance
              ),
              const SizedBox(height: 16),

              _buildTextField(
                  'IFSC Code',
                  _ifscController,
                  TextInputType.text,
                  _validateIFSC,
                  icon: Icons.code,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 11
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleSubmitKYC,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                      'Submit Verification',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          letterSpacing: 0.5
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      TextInputType type,
      String? Function(String?)? validator, {
        int maxLines = 1,
        IconData? icon,
        TextCapitalization textCapitalization = TextCapitalization.none,
        int? maxLength
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: textCapitalization,
      inputFormatters: [
        if (type == TextInputType.number) FilteringTextInputFormatter.digitsOnly,
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[500], size: 22) : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2)
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        counterText: '',
      ),
    );
  }
}
