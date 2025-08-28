
import 'package:flutter/material.dart';
import 'services/file_upload_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Upload Demo',
      home: FileUploadPage(),
    );
  }
}

class FileUploadPage extends StatefulWidget {
  @override
  _FileUploadPageState createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  List<WebFile> _files = [];
  String? _result;
  bool _isUploading = false;
  final _questionController = TextEditingController();

  void _pickFiles() async {
    final files = await FileUploadService.pickFiles();
    if (files != null) {
      setState(() {
        _files = files;
      });
    }
  }

  void _upload() async {
    setState(() {
      _isUploading = true;
    });

    final result = await FileUploadService.uploadFiles(
      question: _questionController.text.isEmpty 
          ? 'Phân tích file này' 
          : _questionController.text,
      sessionId: '1e351958-2a73-4f99-a703-3dc1af1f909c',
      files: _files.isEmpty ? null : _files,
    );

    setState(() {
      _result = result;
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('File Upload Test')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                labelText: 'Câu hỏi (không bắt buộc)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _pickFiles,
              child: Text('Chọn Files'),
            ),
            
            if (_files.isNotEmpty) ...[
              SizedBox(height: 10),
              Text('Đã chọn: ${_files.length} file(s)'),
              ..._files.map((f) => Text('• ${f.name}')),
            ],
            
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isUploading ? null : _upload,
              child: _isUploading 
                  ? Text('Đang upload...') 
                  : Text('Gửi lên API'),
            ),
            
            if (_result != null) ...[
              SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(border: Border.all()),
                  child: SingleChildScrollView(
                    child: Text(_result!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}