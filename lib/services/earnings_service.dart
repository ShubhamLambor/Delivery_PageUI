// services/earnings_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class EarningsService {
  static const String baseUrl = 'https://svtechshant.com/tiffin/api/delivery';

  static Future<Map<String, dynamic>> getPartnerEarnings({
    required String deliveryPartnerId,
    String period = 'today', // today | week | month | all
  }) async {
    final uri = Uri.parse('$baseUrl/get_partner_earnings.php');

    try {
      print('📊 [EARNINGS] Fetching for partner: $deliveryPartnerId, period: $period');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'delivery_partner_id': deliveryPartnerId,
          'period': period,
        },
      );

      print('📥 [EARNINGS] Response status: ${response.statusCode}');
      print('📥 [EARNINGS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : {'success': false};
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('❌ [EARNINGS] Error: $e');
      return {
        'success': false,
        'message': 'Network error: $e'
      };
    }
  }
}
