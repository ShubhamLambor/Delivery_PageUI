// lib/services/map_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MapService {
  // Your live production API URL
  static const String apiUrl = 'https://svtechshant.com/tiffin/api/delivery/get_mess_locations.php';

  /// Fetches nearby messes from the database.
  /// Optionally accepts an [area] parameter to filter the results.
  static Future<List<Map<String, dynamic>>> fetchNearbyMesses({String? area}) async {
    try {
      // 1. Prepare the URL-encoded body
      Map<String, String> body = {};

      // Only add the area to the body if it was provided
      if (area != null && area.isNotEmpty) {
        body['area'] = area;
      }

      // 2. Send the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        // This header is crucial! It tells PHP to read this as $_POST data
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      // 3. Handle the response
      if (response.statusCode == 200) {
        // Parse the raw JSON string into a Dart List
        final List<dynamic> data = json.decode(response.body);

        // Safely cast it so Flutter knows exactly what data type it is dealing with
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('❌ Failed to load mess locations. Status Code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching messes: $e');
      return [];
    }
  }
}