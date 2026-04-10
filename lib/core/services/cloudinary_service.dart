import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class CloudinaryService {
  static const String cloudName = 'dm7gekbgk';
  static const String uploadPreset = 'evnity';

  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from the gallery
  static Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// Pick an image from camera
  static Future<File?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// Pick any file (PDF, image, etc.) using file_picker
  static Future<File?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;
    return File(path);
  }

  /// Upload any file to Cloudinary (auto-detects resource type)
  static Future<String?> uploadFile(File file) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final resourceType = _getResourceType(ext);

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
      );
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'] as String?;
      } else {
        throw Exception(
          'Cloudinary error: ${jsonResponse['error']?['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('File Upload Error: $e');
      return null;
    }
  }

  /// Upload an image file to Cloudinary and return the secure_url
  static Future<String?> uploadImage(File file) async {
    return uploadFile(file);
  }

  /// Returns true if URL points to an image
  static bool isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.gif') ||
        lower.contains('.webp') ||
        lower.contains('/image/upload/');
  }

  static String _getResourceType(String ext) {
    const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'];
    const videoExts = ['mp4', 'mov', 'avi', 'mkv'];
    if (imageExts.contains(ext)) return 'image';
    if (videoExts.contains(ext)) return 'video';
    return 'raw';
  }
}
