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

// /// 🗓️ Builds a styled date picker field used in forms (e.g., DOB, event date)
// Widget buildDatePickerField({
//   required BuildContext context,
//   required String label,
//   required TextEditingController controller,
//   required bool enabled,
//   required void Function(DateTime selectedDate) onDateSelected,
// }) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 8.0),
//     child: TextField(
//       controller: controller,
//       readOnly: true, // Always readonly — opens date picker on tap
//       enabled: enabled,
//       decoration: InputDecoration(
//         labelText: label,
//         suffixIcon: Icon(Icons.calendar_today),
//         border: OutlineInputBorder(),
//       ),
//       onTap: enabled
//           ? () async {
//               FocusScope.of(context).unfocus(); // Dismiss keyboard

//               DateTime? pickedDate = await showDatePicker(
//                 context: context,
//                 initialDate: DateTime.now(),
//                 firstDate: DateTime(1900),
//                 lastDate: DateTime(2100),
//               );

//               if (pickedDate != null) {
//                 controller.text = "${pickedDate.toLocal()}".split(' ')[0]; // Format: yyyy-MM-dd
//                 onDateSelected(pickedDate);
//               }
//             }
//           : null,
//     ),
//   );
// }

// /// ⏰ Builds a time picker field for selecting a time (e.g., departure time)
// Widget buildTimePickerField({
//   required BuildContext context,
//   required String label,
//   required TextEditingController controller,
//   required bool enabled,
//   required void Function(TimeOfDay selectedTime) onTimeSelected,
// }) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 8.0),
//     child: TextField(
//       controller: controller,
//       readOnly: true,
//       enabled: enabled,
//       decoration: InputDecoration(
//         labelText: label,
//         suffixIcon: Icon(Icons.access_time),
//         border: OutlineInputBorder(),
//       ),
//       onTap: enabled
//           ? () async {
//               FocusScope.of(context).unfocus(); // Dismiss keyboard
//               TimeOfDay? picked = await showTimePicker(
//                 context: context,
//                 initialTime: TimeOfDay.now(),
//               );

//               if (picked != null) {
//                 controller.text = picked.format(context);
//                 onTimeSelected(picked);
//               }
//             }
//           : null,
//     ),
//   );
// }


