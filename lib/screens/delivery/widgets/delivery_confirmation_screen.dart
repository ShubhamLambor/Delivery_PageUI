// lib/screens/delivery/delivery_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/delivery_model.dart';
import '../../../services/delivery_service.dart';
import '../../map/osm_navigation_screen.dart';
import '../order_tracking_controller.dart';

class DeliveryConfirmationScreen extends StatefulWidget {
  final DeliveryModel order;

  const DeliveryConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  State<DeliveryConfirmationScreen> createState() => _DeliveryConfirmationScreenState();
}

class _DeliveryConfirmationScreenState extends State<DeliveryConfirmationScreen> {
  bool _isProcessing = false;

  Future<void> _startOtpFlow(BuildContext context) async {
    final controller = context.read<OrderTrackingController>();
    final orderId = widget.order.id;

    setState(() => _isProcessing = true);

    try {
      // ✅ 1. Generate OTP (Now safely passing customerId to satisfy backend requirements)
      final gen = await DeliveryService.generateDeliveryOtp(
        orderId: orderId,
        customerId: widget.order.customerId,
      );

      if (gen['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(gen['message'] ?? 'Failed to generate OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // 2. Show OTP Input Bottom Sheet
      final otpController = TextEditingController();
      final enteredOtp = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
                const SizedBox(height: 12),
                const Text(
                  'Enter Delivery OTP',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask ${widget.order.customerName} for the 4-digit OTP to confirm delivery.', // 👈 Change 6-digit to 4-digit
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4, // 👈 Change 6 to 4
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "••••", // 👈 Change 6 dots to 4 dots
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.green, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx, otpController.text.trim());
                        },
                        child: const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      // If user canceled the bottom sheet
      if (enteredOtp == null || enteredOtp.isEmpty) return;

      setState(() => _isProcessing = true);

      // 3. Verify the OTP
      final verify = await DeliveryService.verifyDeliveryOtp(
        orderId: orderId,
        otp: enteredOtp,
      );

      if (verify['success'] == true) {
        // 4. Mark Delivered in DB (This finalizes status & adds earnings)
        final success = await controller.markDelivered();

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Delivery Completed Successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(controller.errorMessage ?? 'Error finalizing delivery.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(verify['message'] ?? 'Invalid OTP entered.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred during verification.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivered = widget.order.status.toLowerCase() == 'delivered';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            delivered ? Icons.celebration : Icons.delivery_dining,
            size: 72,
            color: delivered ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            delivered ? 'Order Delivered' : 'On the way',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            delivered
                ? 'You have successfully delivered the order to the customer.'
                : 'Deliver the order to the customer and complete with OTP.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(widget.order.customerName),
            subtitle: Text(widget.order.deliveryAddress ?? ''),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.currency_rupee),
            title: Text(widget.order.amount),
            subtitle: const Text('Total earnings (including delivery fee)'),
          ),

          const Spacer(),

          // --- BUTTONS FOR "IN TRANSIT" STAGE ---
          if (!delivered) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.navigation),
                label: const Text('Navigate to Customer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isProcessing
                    ? null
                    : () {
                  if (widget.order.latitude != null && widget.order.longitude != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OSMNavigationScreen(
                          destinationLat: widget.order.latitude!,
                          destinationLng: widget.order.longitude!,
                          destinationName: widget.order.customerName,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Customer location not available'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.verified_user),
                label: Text(_isProcessing ? 'Verifying...' : 'Enter OTP & Deliver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isProcessing ? null : () => _startOtpFlow(context),
              ),
            ),
          ],

          // --- BUTTON FOR "DELIVERED" STAGE ---
          if (delivered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to Home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back to Home', style: TextStyle(fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }
}