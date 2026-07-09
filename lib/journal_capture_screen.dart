import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';

// ضع مفتاح Groq الخاص بك هنا
const String groqApiKey = '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';
const String groqModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

class JournalCaptureScreen extends StatefulWidget {
  const JournalCaptureScreen({super.key});

  @override
  State<JournalCaptureScreen> createState() => _JournalCaptureScreenState();
}

class _JournalCaptureScreenState extends State<JournalCaptureScreen> {
  final Color themeColor = const Color(0xFFB08D57);
  File? _image;
  bool _loading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _items = [];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _items = [];
        _errorMessage = null;
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      const prompt = '''
أنت مساعد لقراءة دفاتر يومية مصنع عربية مكتوبة بخط اليد.
اقرأ الصورة المرفقة واستخرج كل الحركات المالية المذكورة فيها.

أرجع النتيجة بصيغة JSON فقط بدون أي نص إضافي، على الشكل التالي:

{
  "items": [
    {
      "category": "employee",
      "name": "اسم الموظف كما هو مكتوب",
      "type": "production",
      "quantity": 10,
      "amount": 0,
      "note": ""
    }
  ]
}

القواعد:
- category تكون واحدة من: employee (موظف), merchant (تاجر), expense (مصروف)
- إذا كانت employee فـ type تكون: production (إنتاج), advance (سلفة), payment (صرف)
- إذا كانت merchant فـ type تكون: received (مستلم), remaining (متبقي)
- إذا كانت expense فـ type تكون اسم نوع المصروف مثل: كهرباء، بترول، إيجار، نقل، صيانة، مواد، أخرى
- quantity للكمية (خاص بالإنتاج فقط)، amount للمبلغ بالريال
- إذا لم تستطع تحديد نوع سطر معين، تجاهله ولا تخترع بيانات
- أرجع فقط JSON صالح بدون Markdown ولا علامات
''';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': groqModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                }
              ]
            }
          ],
          'temperature': 0.2,
          'max_completion_tokens': 2048,
        }),
      );

      if (response.statusCode != 200) {
        setState(() {
          _errorMessage = 'خطأ من الخادم: ${response.statusCode}\n${response.body}';
          _loading = false;
        });
        return;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      String content = data['choices'][0]['message']['content'];

      content = content.replaceAll('```json', '').replaceAll('```', '').trim();

      final parsed = jsonDecode(content);
      final List<dynamic> rawItems = parsed['items'] ?? [];

      setState(() {
        _items = rawItems.map<Map<String, dynamic>>((item) {
          return {
            'category': item['category'] ?? 'expense',
            'name': item['name'] ?? '',
            'type': item['type'] ?? '',
            'quantity': (item['quantity'] ?? 0).toDouble(),
            'amount': (item['amount'] ?? 0).toDouble(),
            'note': item['note'] ?? '',
          };
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التحليل: $e';
        _loading = false;
      });
    }
  }

  Future<void> _postAll() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    int successCount = 0;
    List<String> failedNames = [];

    for (var item in _items) {
      final category = item['category'];
      final name = (item['name'] as String).trim();
      final type = item['type'];
      final quantity = item['quantity'] as double;
      final amount = item['amount'] as double;
      final note = item['note'] as String;

      if (name.isEmpty) continue;

      if (category == 'employee') {
        final emp = await db.query('employees',
            where: 'name LIKE ?', whereArgs: ['%$name%'], limit: 1);
        if (emp.isEmpty) {
          failedNames.add(name);
          continue;
        }
        await db.insert('employee_transactions', {
          'employeeId': emp.first['id'],
          'type': type,
          'quantity': quantity,
          'amount': amount,
          'note': note,
          'date': now,
        });
        successCount++;
      } else if (category == 'merchant') {
        final merch = await db.query('merchants',
            where: 'name LIKE ?', whereArgs: ['%$name%'], limit: 1);
        if (merch.isEmpty) {
          failedNames.add(name);
          continue;
        }
        await db.insert('merchant_transactions', {
          'merchantId': merch.first['id'],
          'type': type,
          'amount': amount,
          'note': note,
          'date': now,
        });
        successCount++;
      } else {
        await db.insert('expenses', {
          'category': type.isNotEmpty ? type : name,
          'amount': amount,
          'note': note,
          'date': now,
          'createdAt': now,
        });
        successCount++;
      }
    }

    if (_image != null) {
      await db.insert('journal_entries', {
        'imagePath': _image!.path,
        'extractedText': jsonEncode(_items),
        'status': 'posted',
        'date': now,
        'createdAt': now,
      });
    }

    if (mounted) {
      String message = 'تم ترحيل $successCount حركة بنجاح';
      if (failedNames.isNotEmpty) {
        message += '\nلم يتم العثور على: ${failedNames.join(', ')}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      setState(() {
        _items = [];
        _image = null;
      });
    }
  }

  String _categoryLabel(String c) {
    switch (c) {
      case 'employee':
        return 'موظف';
      case 'merchant':
        return 'تاجر';
      default:
        return 'مصروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('تصوير اليومية', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_image!, height: 220, fit: BoxFit.cover, width: double.infinity),
            )
          else
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(Icons.receipt_long, size: 60, color: themeColor.withOpacity(0.4)),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text('تصوير', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor.withOpacity(0.7)),
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  label: const Text('من المعرض', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_image != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C3E67),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _loading ? null : _analyzeImage,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(_loading ? 'جاري التحليل...' : 'تحليل الصورة بالذكاء الاصطناعي',
                  style: const TextStyle(color: Colors.white)),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('راجع البيانات قبل الترحيل:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: Text(_categoryLabel(item['category']),
                                style: const TextStyle(fontSize: 11, color: Colors.white)),
                            backgroundColor: themeColor,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => setState(() => _items.removeAt(index)),
                          ),
                        ],
                      ),
                      TextFormField(
                        initialValue: item['name'],
                        decoration: const InputDecoration(labelText: 'الاسم'),
                        onChanged: (v) => item['name'] = v,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item['type'].toString(),
                              decoration: const InputDecoration(labelText: 'النوع'),
                              onChanged: (v) => item['type'] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item['quantity'].toString(),
                              decoration: const InputDecoration(labelText: 'الكمية'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => item['quantity'] = double.tryParse(v) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item['amount'].toString(),
                              decoration: const InputDecoration(labelText: 'المبلغ'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => item['amount'] = double.tryParse(v) ?? 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D74),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _postAll,
              child: const Text('ترحيل الكل', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }
}
