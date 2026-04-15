import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

Future<String?> pickImageBase64() async {
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.gallery);

  if (image == null) return null;

  final bytes = await image.readAsBytes();
  final ext = image.path.split('.').last;
  return "data:image/$ext;base64,${base64Encode(bytes)}";
}

Future<String?> uploadImageToSupabase(
  int employeeId,
  String base64Image,
) async {
  try {
    final cleanedBase64 = base64Image.split(',').last;
    final bytes = base64Decode(cleanedBase64);

    final isPng = base64Image.contains("image/png");
    final fileExt = isPng ? "png" : "jpg";
    final mimeType = isPng ? "image/png" : "image/jpeg";

    final filePath = "Employee${employeeId}_image.$fileExt";

    final bucket = SupabaseConfig.client.storage.from("image");

    // Optional: delete old file
    await bucket.remove([filePath]).catchError((_) {});

    // Upload (NOT base64, raw bytes)
    final res = await bucket.uploadBinary(
      filePath,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: mimeType),
    );

    // Public URL
    return bucket.getPublicUrl(filePath);
  } catch (e) {
    debugPrint("❌ Upload error: $e");
    return null;
  }
}

/// Update employee table with image URL
Future<bool> updateEmployeeImage(int employeeId, String imageUrl) async {
  try {
    await SupabaseConfig.client
        .from("employee")
        .update({"employeeimage": imageUrl})
        .eq("employeeid", employeeId);

    return true;
  } catch (e) {
    debugPrint("❌ DB update error: $e");
    return false;
  }
}
