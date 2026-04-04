// lib/screens/delivery/widgets/delivery_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:slide_to_act/slide_to_act.dart';
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
      // 1. Generate the OTP first so the customer receives it
      final gen = await DeliveryService.generateDeliveryOtp(
        orderId: orderId,
        customerId: widget.order.customerId,
      );

      if (gen['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(gen['message'] ?? 'Failed to generate OTP'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // 2. Show the Bottom Sheet for the driver to enter the OTP
      final otpController = TextEditingController();

      // Use a boolean result to check if verification was successful
      final isSuccess = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          // Add local state variables for the Bottom Sheet
          bool isVerifying = false;
          String? otpError;

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 24, right: 24, top: 24,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
                    const SizedBox(height: 12),
                    const Text('Enter Delivery OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Ask ${widget.order.customerName} for the 4-digit OTP to confirm delivery.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 30),

                    // Beautiful Pinput with Error Handling
                    Pinput(
                      length: 4,
                      controller: otpController,
                      autofocus: true,
                      forceErrorState: otpError != null, // Triggers the error theme
                      onChanged: (value) {
                        // Clear error when user starts typing again
                        if (otpError != null) {
                          setModalState(() {
                            otpError = null;
                          });
                        }
                      },
                      defaultPinTheme: PinTheme(
                        width: 60,
                        height: 64,
                        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 60,
                        height: 64,
                        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                      ),
                      // NEW: Error theme for wrong OTP
                      errorPinTheme: PinTheme(
                        width: 60,
                        height: 64,
                        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                      ),
                    ),

                    // Show beautiful error message if present
                    if (otpError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              otpError!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isVerifying ? null : () => Navigator.pop(ctx, false),
                            child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.black54)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: isVerifying ? null : () async {
                              final enteredOtp = otpController.text.trim();
                              if (enteredOtp.length < 4) {
                                setModalState(() => otpError = 'Please enter 4 digits.');
                                return;
                              }

                              setModalState(() {
                                isVerifying = true;
                                otpError = null;
                              });

                              // 3. SECURE STEP: Call markDelivered with the OTP inside the modal.
                              final success = await controller.markDelivered(enteredOtp);

                              if (success) {
                                // Success! Close the modal and return true
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              } else {
                                // Failure! Show error, keep modal open
                                setModalState(() {
                                  isVerifying = false;
                                  otpError = controller.errorMessage ?? 'Wrong OTP, please try again.';
                                  otpController.clear(); // Optional: clear the pin fields for them to re-type easily
                                });
                              }
                            },
                            child: isVerifying
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : const Text('Verify & Deliver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      // 4. Handle UI update after successful verification
      if (isSuccess == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [Icon(Icons.celebration, color: Colors.white), SizedBox(width: 12), Text('Delivery Completed Successfully!')]),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred during verification.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivered = widget.order.status.toLowerCase() == 'delivered';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: delivered ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      delivered ? Icons.check_circle : Icons.delivery_dining,
                      size: 64,
                      color: delivered ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    delivered ? 'Order Delivered' : 'On the way',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    delivered
                        ? 'You have successfully delivered the order to the customer.'
                        : 'Deliver the order to the customer and complete with OTP.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          title: Text(widget.order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(widget.order.deliveryAddress ?? '', style: TextStyle(color: Colors.grey[600])),
                        ),
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.1),
                            child: const Icon(Icons.currency_rupee, color: Colors.green),
                          ),
                          title: Text('₹${widget.order.amount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: const Text('Total order value'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!delivered) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.navigation),
                label: const Text('Navigate to Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      const SnackBar(content: Text('Customer location not available'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // NEW: Slider Button for triggering OTP
            SizedBox(
              width: double.infinity,
              child: _isProcessing
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.green),
                ),
              )
                  : SlideAction(
                text: 'Slide to Enter OTP',
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                outerColor: Colors.green,
                innerColor: Colors.white,
                sliderButtonIcon: const Icon(Icons.arrow_forward_ios, color: Colors.green, size: 20),
                submittedIcon: const Icon(Icons.lock_outline, color: Colors.green),
                borderRadius: 12,
                elevation: 0,
                onSubmit: () async {
                  // Trigger the OTP flow
                  await _startOtpFlow(context);
                  // Returning null automatically resets the slider
                  return null;
                },
              ),
            ),
          ],

          if (delivered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}