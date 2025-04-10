// 📦 Filename: file_utils.dart
// 📂 Location: lib/utils/

import 'package:file_picker/file_picker.dart';

/// Utility class to encapsulate file picking functionality.
class FileUtils {
  /// Prompts user to select a file and returns the file path.
  ///
  /// [allowedExtensions] - Optional file types like ['jpg', 'pdf'].
  /// Returns null if user cancels selection.
  static Future<String?> pickFile({List<String>? allowedExtensions}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      return result.files.single.path;
    }

    return null; // User cancelled
  }
}
