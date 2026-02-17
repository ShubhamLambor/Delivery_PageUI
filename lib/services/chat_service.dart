import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // ✅ Your server IP
  static const String _baseUrl = "https://deliver-chatbot.onrender.com";

  /// Sends a message to the chatbot and returns the response
  Future<ChatbotResponse> sendMessage(String message, {String userId = "flutter_user"}) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": message,
          "user_id": userId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatbotResponse(
          message: data['response'],
          status: data['status'],
          confidence: (data['confidence'] ?? 0.0).toDouble(),
        );
      } else if (response.statusCode == 400) {
        return ChatbotResponse(
          message: "Please enter a valid message.",
          status: "error",
          confidence: 0.0,
        );
      } else {
        return ChatbotResponse(
          message: "Server error (${response.statusCode}). Please try again.",
          status: "error",
          confidence: 0.0,
        );
      }
    } on http.ClientException catch (_) {
      return ChatbotResponse(
        message: "Network error. Check your internet connection.",
        status: "error",
        confidence: 0.0,
      );
    } on FormatException catch (_) {
      return ChatbotResponse(
        message: "Invalid response from server.",
        status: "error",
        confidence: 0.0,
      );
    } catch (e) {
      return ChatbotResponse(
        message: "Connection failed. Is the chatbot server running?",
        status: "error",
        confidence: 0.0,
      );
    }
  }

  /// Check if server is online
  Future<bool> checkServerHealth() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Response model
class ChatbotResponse {
  final String message;
  final String status;
  final double confidence;

  ChatbotResponse({
    required this.message,
    required this.status,
    required this.confidence,
  });

  bool get isSuccess => status == "success";
  bool get isError => status == "error";
}
