// 📂 lib/utils/ui_helpers.dart
import 'package:flutter/material.dart';
import 'package:kccarpoolapp/services/firebase_functions.dart';
import 'package:kccarpoolapp/utils/file_utils.dart';

/// Type definition for a function that takes a file path and updates state
typedef FileSetter = void Function(String path);

/// 🔁 Handles the full file upload flow using FileUtils + saveFileLocally.
Future<void> handleFileUpload({
  required BuildContext context,
  required String fileType,
  required FileSetter onFilePicked,
  required FirebaseFunctions firebaseFunctions,
  List<String>? allowedExtensions,
}) async {
  // Step 1: Pick a file
  String? pickedPath = await FileUtils.pickFile(
    allowedExtensions: allowedExtensions ?? ['jpg', 'jpeg', 'png', 'pdf'],
  );

  if (pickedPath != null) {
    // Step 2: Save it locally
    String? savedPath = await firebaseFunctions.saveFileLocally(fileType, pickedPath);

    if (savedPath != null) {
      onFilePicked(savedPath); // Step 3: Notify caller
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to save file locally."),
        backgroundColor: Colors.red,
      ));
    }
  }
}

/// 🔁 Builds a consistent file upload section for any screen.
Widget buildFileUploadSection({
  required BuildContext context,
  required String label,
  required String fileType,
  required String? currentPath,
  required FirebaseFunctions firebaseFunctions,
  required FileSetter onFilePicked,
  List<String>? allowedExtensions,
}) {
  return ListTile(
    title: Text(label),
    subtitle: currentPath != null ? Text("Uploaded") : Text("Not uploaded"),
    trailing: ElevatedButton(
      onPressed: () => handleFileUpload(
        context: context,
        fileType: fileType,
        firebaseFunctions: firebaseFunctions,
        onFilePicked: onFilePicked,
        allowedExtensions: allowedExtensions,
      ),
      child: Text(currentPath != null ? "Replace" : "Upload"),
    ),
  );
}

/// 🔁 Builds a reusable text field with optional editability (used in profile/family screens)
Widget buildTextField({
  required String label,
  required TextEditingController controller,
  bool enabled = true,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

// /// 🗓️ Shared Date Picker Field
// ///
// /// Displays a label and the selected date. Triggers `onTap()` when tapped.
// /// Doesn't include date picker logic — allows screens to handle their own `showDatePicker()`
// /// constraints (e.g., future vs past dates).
// Widget buildDatePickerField({
//   required String label,
//   required DateTime? selectedDate,
//   required VoidCallback onTap,
//   bool asTextField = false,
// }) {
//   final String displayText = selectedDate != null
//       ? "${selectedDate.day.toString().padLeft(2, '0')}/"
//         "${selectedDate.month.toString().padLeft(2, '0')}/"
//         "${selectedDate.year}"
//       : label;

//   if (asTextField) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: TextField(
//         readOnly: true,
//         onTap: onTap,
//         decoration: InputDecoration(
//           labelText: label,
//           hintText: displayText,
//           suffixIcon: Icon(Icons.calendar_today),
//         ),
//       ),
//     );
//   }

//   return ListTile(
//     title: Text(displayText),
//     trailing: Icon(Icons.calendar_today),
//     onTap: onTap,
//   );
// }


