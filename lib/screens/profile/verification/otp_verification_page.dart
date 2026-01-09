// lib/screens/profile/verification/otp_verification_page.dart

import 'package:flutter/material.dart';

class OtpVerificationPage extends StatefulWidget {
  final String channel; // "Email" or "Phone"
  final String destination;

  const OtpVerificationPage({
    super.key,
    required this.channel,
    required this.destination,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _contactController.text = widget.destination;
  }

  @override
  void dispose() {
    _contactController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool get _isPhone => widget.channel.toLowerCase().contains('phone');

  Future<void> _sendOtp() async {
    final target = _contactController.text.trim();
    if (target.isEmpty) {
      _showSnack('Please add your ${widget.channel.toLowerCase()} first.');
      return;
    }

    setState(() {
      _otpSent = true;
    });

    // TODO: Call your API to send OTP
    // Example: await ApiService.sendOtp(target, widget.channel);

    _showSnack('OTP sent to $target');
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      _showSnack('Enter the OTP you received.');
      return;
    }

    setState(() {
      _verifying = true;
    });

    // TODO: Call your API to verify OTP
    // Example: final response = await ApiService.verifyOtp(widget.destination, otp);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _verifying = false;
    });

    _showSnack('${widget.channel} verified successfully.');

    // Return true to indicate successful verification
    Navigator.of(context).pop(true);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _isPhone ? Colors.teal : Colors.blue;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('${widget.channel} verification'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isPhone ? Icons.sms : Icons.mail_outline,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.channel} verification',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isPhone
                                ? 'We will send a 6-digit code to your mobile number.'
                                : 'We will send a 6-digit code to your email address.',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isPhone ? 'Mobile number' : 'Email address',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contactController,
                keyboardType: _isPhone
                    ? TextInputType.phone
                    : TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: _isPhone ? 'Enter mobile number' : 'Enter email',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    _isPhone ? Icons.phone_iphone : Icons.email_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'One-time password',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _otpSent ? _sendOtp : null,
                    child: const Text('Resend OTP'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter 6-digit code',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _sendOtp,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _otpSent ? 'Send again' : 'Send OTP',
                        style: TextStyle(color: accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _verifying
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Verify'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Note: This is a UI-only flow. Wire it to your OTP API to complete verification.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
