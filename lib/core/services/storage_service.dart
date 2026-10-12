import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'supabase_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage(ImageSource source) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('[StorageService] Error picking image: $e');
      return null;
    }
  }

  /// Uploads or saves the photo.
  /// If Supabase is connected, uploads to bucket `memory-images`.
  /// Otherwise persists locally in application documents directory.
  Future<String?> saveMemoryImage({
    required XFile imageFile,
    required String memoryId,
    required String userId,
  }) async {
    try {
      final supabase = SupabaseService();
      if (supabase.isInitialized && supabase.client != null) {
        final bytes = await imageFile.readAsBytes();
        final ext = p.extension(imageFile.path).isNotEmpty ? p.extension(imageFile.path) : '.jpg';
        final storagePath = '$userId/$memoryId$ext';

        await supabase.client!.storage.from('memory-images').uploadBinary(
              storagePath,
              bytes,
            );

        final publicUrl = supabase.client!.storage
            .from('memory-images')
            .getPublicUrl(storagePath);

        return publicUrl;
      }

      // Fallback: Local persistent storage
      if (!kIsWeb) {
        final docDir = await getApplicationDocumentsDirectory();
        final ext = p.extension(imageFile.path).isNotEmpty ? p.extension(imageFile.path) : '.jpg';
        final localFile = File('${docDir.path}/time_capsule_$memoryId$ext');
        final bytes = await imageFile.readAsBytes();
        await localFile.writeAsBytes(bytes);
        return localFile.path;
      }

      return imageFile.path;
    } catch (e) {
      debugPrint('[StorageService] Failed to save memory image: $e');
      return null;
    }
  }
}
