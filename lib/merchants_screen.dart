import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';

class MerchantsScreen extends StatefulWidget {
  const MerchantsScreen({super.key});

  @override
  State<MerchantsScreen> createState() => _MerchantsScreenState();
}

class _MerchantsScreenState extends State<MerchantsScreen> {
  List<Map<String, dynamic>> _merchants = [];
  final Color themeColor = const Color(0xFF6B8E4E);

  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  Future<void> _loadMerchants() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('merchants', orderBy: 'id DESC');
    setState(() {
      _merchants = data;
    });
  }

  Future<void> _deleteMerchant(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('merchants', where: 'id = ?', whereArgs: [id]);
    _loadMerchants();
  }

  void _openAddMerchantSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMerchantSheet(
        themeColor: themeColor,
        onSaved: _loadMerchants,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('التجار', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _merchants.isEmpty
          ? const Center(child: Text('لا يوجد تجار بعد، اضغط + للإضافة'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _merchants.length,
              itemBuilder: (context, index) {
                final m = _merchants[index];
                final relationType = m['relationType'] ?? 'بضاعة';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: themeColor.withOpacity(0.15),
                      backgroundImage: m['photoPath'] != null
                          ? FileImage(File(m['photoPath']))
                          : null,
                      child: m['photoPath'] == null
                          ? Icon(Icons.storefront, color: themeColor)
                          : null,
                    ),
                    title: Text(
                      m['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$relationType - ${m['city'] ?? ''} - ${m['phone'] ?? ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteMerchant(m['id']),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        onPressed: _openAddMerchantSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _AddMerchantSheet extends StatefulWidget {
  final Color themeColor;
  final VoidCallback onSaved;

  const _AddMerchantSheet({required this.themeColor, required this.onSaved});

  @override
  State<_AddMerchantSheet> createState() => _AddMerchantSheetState();
}

class _AddMerchantSheetState extends State<_AddMerchantSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();
  String _relationType = 'بضاعة';
  File? _photo;

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _photo = File(picked.path);
      });
    }
  }

  Future<void> _saveMerchant() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم التاجر')),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.insert('merchants', {
      'name': _nameController.text.trim(),
      'photoPath': _photo?.path,
      'phone': _phoneController.text.trim(),
      'city': _cityController.text.trim(),
      'relationType': _relationType,
      'notes': _notesController.text.trim(),
      'createdAt': now,
      'updatedAt': now,
    });

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'إضافة تاجر جديد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.themeColor,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('تصوير'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickPhoto(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('من المعرض'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickPhoto(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: widget.themeColor.withOpacity(0.15),
                  backgroundImage: _photo != null ? FileImage(_photo!) : null,
                  child: _photo == null
                      ? Icon(Icons.camera_alt, color: widget.themeColor)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('نوع العلاقة', style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('بضاعة'),
                    selected: _relationType == 'بضاعة',
                    selectedColor: widget.themeColor.withOpacity(0.25),
                    onSelected: (_) => setState(() => _relationType = 'بضاعة'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('تشغيل'),
                    selected: _relationType == 'تشغيل',
                    selectedColor: widget.themeColor.withOpacity(0.25),
                    onSelected: (_) => setState(() => _relationType = 'تشغيل'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم',
                prefixIcon: Icon(Icons.person, color: widget.themeColor),
              ),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone, color: widget.themeColor),
              ),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'المدينة',
                prefixIcon: Icon(Icons.location_city, color: widget.themeColor),
              ),
            ),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.note, color: widget.themeColor),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saveMerchant,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('حفظ', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
