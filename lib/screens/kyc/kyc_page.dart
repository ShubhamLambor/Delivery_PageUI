import 'package:flutter/material.dart';

class KYCPage extends StatefulWidget {
  const KYCPage({super.key});

  @override
  State<KYCPage> createState() => _KYCPageState();
}

class _KYCPageState extends State<KYCPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _aadharController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // --- Validators ---
  String? _validateAadhar(String? value) {
    if (value == null || value.isEmpty) return 'Aadhaar is required';
    final cleaned = value.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length != 12) return 'Aadhaar must be 12 digits';
    if (!RegExp(r'^\d{12}$').hasMatch(cleaned)) return 'Invalid Aadhaar format';
    return null;
  }

  String? _validatePAN(String? value) {
    if (value == null || value.isEmpty) return 'PAN is required';
    if (value.length != 10) return 'PAN must be 10 characters';
    return null;
  }

  Future<void> _handleSubmitKYC() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loading = true);

    // Simulate API call
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KYC Submitted Successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Go back after success

    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('KYC Verification', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Personal Identity'),
              const SizedBox(height: 16),

              _buildTextField('Aadhaar Number', _aadharController, TextInputType.number, _validateAadhar, icon: Icons.badge),
              const SizedBox(height: 16),
              _buildTextField('PAN Card Number', _panController, TextInputType.text, _validatePAN, icon: Icons.credit_card, textCapitalization: TextCapitalization.characters),

              const SizedBox(height: 24),
              _buildSectionHeader('Address Details'),
              const SizedBox(height: 16),

              _buildTextField('Full Street Address', _addressController, TextInputType.streetAddress, (v) => v!.isEmpty ? 'Required' : null, maxLines: 3, icon: Icons.home),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildTextField('City', _cityController, TextInputType.text, (v) => v!.isEmpty ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Pincode', _pincodeController, TextInputType.number, (v) => v!.length != 6 ? 'Invalid' : null)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('State', _stateController, TextInputType.text, (v) => v!.isEmpty ? 'Required' : null),

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700], letterSpacing: 0.5),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      TextInputType type,
      String? Function(String?)? validator,
      {int maxLines = 1, IconData? icon, TextCapitalization textCapitalization = TextCapitalization.none}
      ) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[500], size: 22) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
