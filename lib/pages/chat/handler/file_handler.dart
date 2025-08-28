// // handler/file_handler.dart
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'dart:html' as html; // Add this for web

// // Abstract base class for file operations
// abstract class BaseFile {
//   String get name;
//   String get path;
//   int get size;
//   Future<Uint8List> readAsBytes();
//   Future<int> length();
//   Future<bool> exists();
// }

// // Web-compatible File implementation - SIMPLIFIED
// class WebFile implements BaseFile {
//   @override
//   final String name;
//   @override
//   final int size;
//   final html.File _htmlFile;

//   WebFile({
//     required this.name,
//     required this.size,
//     required html.File htmlFile,
//   }) : _htmlFile = htmlFile;

//   @override
//   String get path => name; // Use name as identifier

//   @override
//   Future<int> length() async => size;

//   @override
//   Future<bool> exists() async => true;

//   @override
//   Future<Uint8List> readAsBytes() async {
//     final reader = html.FileReader();
//     reader.readAsArrayBuffer(_htmlFile);
//     await reader.onLoad.first;
//     return reader.result as Uint8List;
//   }
// }

// // Native file wrapper
// class NativeFile implements BaseFile {
//   final File _file;

//   NativeFile(this._file);

//   @override
//   String get name => _file.path.split('/').last;

//   @override
//   String get path => _file.path;

//   @override
//   int get size => _file.lengthSync();

//   @override
//   Future<Uint8List> readAsBytes() => _file.readAsBytes();

//   @override
//   Future<int> length() => _file.length();

//   @override
//   Future<bool> exists() => _file.exists();

//   File get file => _file;
// }

// class FileHandler {
//   // Updated to only support txt, docx, pdf, csv
//   static const List<String> allowedExtensions = [
//     'txt',
//     'docx', 
//     'pdf',
//     'csv'
//   ];

//   static const int maxFileSize = 50 * 1024 * 1024; // 50MB
//   static const int maxFiles = 10;

//   static Future<List<BaseFile>?> pickFiles({
//     List<String>? allowedExtensions,
//     bool allowMultiple = true,
//   }) async {
//     try {
//       print('Starting file picker...');

//       if (kIsWeb) {
//         // Use HTML file picker for web - SIMPLIFIED
//         return await _pickFilesWeb(
//           allowedExtensions: allowedExtensions ?? FileHandler.allowedExtensions,
//           allowMultiple: allowMultiple,
//         );
//       } else {
//         // Use regular file picker for mobile/desktop
//         return await _pickFilesNative(
//           allowedExtensions: allowedExtensions ?? FileHandler.allowedExtensions,
//           allowMultiple: allowMultiple,
//         );
//       }
//     } catch (e) {
//       print('File picker error: $e');
//       throw FilePickerException('Failed to select files: ${e.toString()}');
//     }
//   }

//   static Future<List<BaseFile>?> _pickFilesWeb({
//     required List<String> allowedExtensions,
//     required bool allowMultiple,
//   }) async {
//     final html.InputElement input = html.InputElement(type: 'file');
//     input.multiple = allowMultiple;
//     input.accept = allowedExtensions.map((ext) => '.$ext').join(',');
//     input.click();

//     await input.onChange.first;

//     if (input.files != null && input.files!.isNotEmpty) {
//       final List<BaseFile> files = [];
      
//       for (final htmlFile in input.files!) {
//         // Basic validation
//         if (htmlFile.size > maxFileSize) {
//           throw FilePickerException(
//               'File too large: ${htmlFile.name}. Max: ${maxFileSize ~/ (1024 * 1024)}MB');
//         }

//         if (htmlFile.size == 0) {
//           throw FilePickerException('File is empty: ${htmlFile.name}');
//         }

//         // Validate extension
//         final extension = htmlFile.name.split('.').last.toLowerCase();
//         if (!allowedExtensions.contains(extension)) {
//           throw FilePickerException(
//               'Unsupported file type: ${htmlFile.name}');
//         }

//         // Create WebFile - SIMPLIFIED
//         files.add(WebFile(
//           name: htmlFile.name,
//           size: htmlFile.size,
//           htmlFile: htmlFile,
//         ));

//         print('✓ Added file: ${htmlFile.name} (${htmlFile.size} bytes)');
//       }

//       if (files.length > maxFiles) {
//         throw FilePickerException(
//             'Too many files selected. Maximum: $maxFiles');
//       }

//       print('Successfully selected ${files.length} files');
//       return files;
//     }
//     return null;
//   }

//   static Future<List<BaseFile>?> _pickFilesNative({
//     required List<String> allowedExtensions,
//     required bool allowMultiple,
//   }) async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: allowedExtensions,
//       allowMultiple: allowMultiple,
//       withData: false, // Don't load data for native files
//       withReadStream: false,
//       allowCompression: false,
//     );

//     if (result == null || result.files.isEmpty) {
//       print('No files selected');
//       return null;
//     }

//     if (result.files.length > maxFiles) {
//       throw FilePickerException(
//           'Too many files selected. Maximum: $maxFiles');
//     }

//     final List<BaseFile> files = [];

//     for (final platformFile in result.files) {
//       try {
//         print('Processing: ${platformFile.name}');

//         if (platformFile.path == null) {
//           throw FilePickerException(
//               'File path not available: ${platformFile.name}');
//         }

//         final nativeFile = File(platformFile.path!);

//         if (!await nativeFile.exists()) {
//           throw FilePickerException(
//               'File does not exist: ${platformFile.name}');
//         }

//         // Test file read access
//         final testRead = await nativeFile.readAsBytes();
//         final fileSize = testRead.length;

//         // Validate file size
//         if (fileSize > maxFileSize) {
//           throw FilePickerException(
//               'File too large: ${platformFile.name}. Max: ${maxFileSize ~/ (1024 * 1024)}MB');
//         }

//         if (fileSize == 0) {
//           throw FilePickerException('File is empty: ${platformFile.name}');
//         }

//         // Validate extension
//         final extension = platformFile.extension?.toLowerCase();
//         if (extension == null || !allowedExtensions.contains(extension)) {
//           throw FilePickerException(
//               'Unsupported file type: ${platformFile.name}');
//         }

//         print('✓ File validated: ${platformFile.name}');
//         files.add(NativeFile(nativeFile));
//       } catch (e) {
//         print('Error processing ${platformFile.name}: $e');
//         rethrow;
//       }
//     }

//     print('Successfully processed ${files.length} files');
//     return files;
//   }

//   static Future<BaseFile?> pickSingleFile({
//     List<String>? allowedExtensions,
//   }) async {
//     final files = await pickFiles(
//       allowedExtensions: allowedExtensions,
//       allowMultiple: false,
//     );

//     return files?.isNotEmpty == true ? files!.first : null;
//   }

//   static String getFileExtension(String filePath) {
//     final lastDot = filePath.lastIndexOf('.');
//     if (lastDot == -1) return '';
//     return filePath.substring(lastDot + 1).toLowerCase();
//   }

//   static String getFileName(String filePath) {
//     return filePath
//         .split('/')
//         .last
//         .split('\\')
//         .last; // Handle both Unix and Windows paths
//   }

//   static String formatFileSize(int bytes) {
//     if (bytes < 1024) return '$bytes B';
//     if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
//     if (bytes < 1024 * 1024 * 1024)
//       return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
//     return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
//   }

//   static bool isDocumentFile(String filePath) {
//     final extension = getFileExtension(filePath);
//     return ['pdf', 'docx', 'txt'].contains(extension);
//   }

//   static bool isSpreadsheetFile(String filePath) {
//     final extension = getFileExtension(filePath);
//     return ['csv'].contains(extension);
//   }

//   static String getFileType(String filePath) {
//     final extension = getFileExtension(filePath);
    
//     if (extension == 'csv') return 'Spreadsheet';
//     if (['pdf', 'docx', 'txt'].contains(extension)) return 'Document';
    
//     return 'Unknown';
//   }

//   // Utility method to convert BaseFile to the appropriate type for API calls
//   static dynamic getFileForUpload(BaseFile file) {
//     if (file is WebFile) {
//       return file;
//     } else if (file is NativeFile) {
//       return file.file;
//     }
//     throw Exception('Unknown file type');
//   }
// }

// class FilePickerException implements Exception {
//   final String message;

//   const FilePickerException(this.message);

//   @override
//   String toString() => 'FilePickerException: $message';
// }
