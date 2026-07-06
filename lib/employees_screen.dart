import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';
import 'employee_ledger_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  List<Map<String, dynamic>> _employees = [];
  final Color themeColor = const Color(0xFF2C3E67);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query('employees', orderBy: 'id DESC');
    setState(() {
      _employees = data;
    });
  }

  Future<void> _deleteEmployee(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('employees', where: 'id = ?', whereArgs: [id]);
    _loadEmployees();
  }

  void _openAddEmployeeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEmployeeSheet(
        themeColor: themeColor,
        onSaved: _loadEmployees,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: const Text('الموظفون', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _employees.isEmpty
          ? const Center(child: Text('لا يوجد موظفون بعد، اضغط + للإضافة'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final emp = _employees[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeLedgerScreen(
                            employeeId: emp['id'],
                          ),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: themeColor.withOpacity(0.15),
                      backgroundImage: emp['photoPath'] != null
                          ? FileImage(File(emp['photoPath']))
                          : null,
                      child: emp['photoPath'] == null
                          ? Icon(Icons.person, color: themeColor)
                          : null,
                    ),
                    title: Text(
                      emp['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${emp['category'] ?? ''} - ${emp['phone'] ?? ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteEmployee(emp['id']),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        onPressed: _openAddEmployeeSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _AddEmployeeSheet extends StatefulWidget {
  final Color themeColor;
  final VoidCallback onSaved;

  const _AddEmployeeSheet({required this.themeColor, required this.onSaved});

  @override
  State<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends State<_AddEmployeeSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
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

  Future<void> _saveEmployee() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم الموظف')),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.insert('employees', {
      'name': _nameController.text.trim(),
      'photoPath': _photo?.path,
      'phone': _phoneController.text.trim(),
      'category': _categoryController.text.trim(),
      'unitPrice': double.tryParse(_priceController.text.trim()) ?? 0,
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
            Center(
              child: Text(
                'إضافة موظف جديد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.themeColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'الصنف'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'سعر الوحدة'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saveEmployee,
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
