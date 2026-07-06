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

  const _AddEmployeeSheet({required this.themeColor, required
