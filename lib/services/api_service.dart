import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: Replace with your Render backend URL (e.g., https://your-app.onrender.com)
  // For local development, use your machine's IP address.
  static const String _baseUrl = "CHANGE_THIS_TO_YOUR_BACKEND_URL";

  static Future<String> uploadPDF(File pdfFile) async {
    var uri = Uri.parse("$_baseUrl/summarize-pdf");

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('pdf', pdfFile.path));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['summary'] ?? "No summary found.";
      } else {
        throw Exception("API failed: ${response.body}");
      }
    } catch (e) {
      print("API Error: $e");
      rethrow;
    }
  }
}
