import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName;
  final String unsignedPreset; // use unsigned preset for client-side uploads

  CloudinaryService({required this.cloudName, required this.unsignedPreset});

  Future<String?> uploadImageFile(
    File file, {
    String folder = 'licenses',
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = unsignedPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['secure_url'] as String?;
    }
    return null;
  }
}
