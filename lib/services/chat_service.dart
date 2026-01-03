import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // ⚠️ REPLACE THIS WITH YOUR IPv4 ADDRESS from step 1
  // Example: "http://192.168.1.5:8000/chat"
  // If using Android Emulator ONLY, you can use "http://10.0.2.2:8000/chat"
  static const String _baseUrl = "http://192.168.X.X:8000/chat";

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": message,
          "user_id": "flutter_user"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response']; // Returns the bot's reply
      } else {
        return "Server error: ${response.statusCode}";
      }
    } catch (e) {
      return "Connection failed: Is the Python server running?";
    }
  }
}
