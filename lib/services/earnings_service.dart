// services/earnings_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class EarningsService {
  static const String baseUrl = 'https://your-domain.com/api/delivery';

  static Future<Map<String, dynamic>> getPartnerEarnings({
    required String deliveryPartnerId,
    String period = 'today', // today | week | month | all
  }) async {
    final uri = Uri.parse('$baseUrl/get_partner_earnings.php');

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

    final data = jsonDecode(response.body);
    return data is Map<String, dynamic> ? data : {'success': false};
  }
}
