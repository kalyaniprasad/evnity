import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Update these when the user provides them
  static const String cloudName = 'dm7gekbgk';
  static const String uploadPreset = 'evnity';

  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from the gallery
  static Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compress slightly
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// Upload the image file to Cloudinary and return the secure_url
  static Future<String?> uploadImage(File file) async {
    if (cloudName == 'YOUR_CLOUD_NAME') {
      throw Exception('Cloudinary Cloud Name is not configured.');
    }

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Cloudinary error: ${jsonResponse['error']['message']}');
      }
    } catch (e) {
      print('Image Upload Error: $e');
      return null;
    }
  }
}
