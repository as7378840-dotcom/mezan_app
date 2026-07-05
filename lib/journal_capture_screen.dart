import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class JournalCaptureScreen extends StatefulWidget {
  const JournalCaptureScreen({super.key});

  @override
  State<JournalCaptureScreen> createState() => _JournalCaptureScreenState();
}

class _JournalCaptureScreenState extends State<JournalCaptureScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: source, imageQuality: 90);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تصوير اليومية'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _selectedImage == null
                    ? const Text('لم يتم اختيار صورة بعد')
                    : Image.file(_selectedImage!),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('تصوير'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('من المعرض'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
