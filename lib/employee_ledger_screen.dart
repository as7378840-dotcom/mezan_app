// employee_ledger_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'database_helper.dart';

class EmployeeLedgerScreen extends StatefulWidget {
  final int employeeId;

  const EmployeeLedgerScreen({super.key, required this.employeeId});

  @override
  State<EmployeeLedgerScreen> createState() => _EmployeeLedgerScreenState();
}

class _EmployeeLedgerScreenState extends State<EmployeeLedgerScreen> {
  final Color themeColor = const Color(0xFF2C3E67);

  Map<String, dynamic>? _employee;
  List<Map<String, dynamic>> _rows = [];

  double _totalDue = 0; // له
  double _totalOwed = 0; // عليه

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;

    final empData = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [widget.employeeId],
    );
    final employee = empData.first;
    final unitPrice = (employee['unitPrice'] as num?)?.toDouble() ?? 0;
    final category = (employee['category'] ?? '').toString();

    final transactions = await db.query(
      'employee_transactions',
      where: 'employeeId = ?',
      whereArgs: [widget.employeeId],
      orderBy: 'date ASC',
    );

    double due = 0;
    double owed = 0;
    final rows = <Map<String, dynamic>>[];

    for (var t in transactions) {
      final type = t['type'] as String;

      if (type == 'production') {
        final qty = (t['quantity'] as num).toDouble();
        final total = qty * unitPrice;
        due += total;
        rows.add({
          'id': t['id'],
          'date': t['date'],
          'production': qty, // كمية الإنتاج
          'qty': qty,
          'category': category,
          'price': unitPrice,
          'payment': 0.0,
          'advance': 0.0,
          'due': total,
          'owed': 0.0,
        });
      } else if (type == 'advance') {
        final amount = (t['amount'] as num).toDouble();
        owed += amount;
        rows.add({
          'id': t['id'],
          'date': t['date'],
          'production': 0.0,
          'qty': null,
          'category': '—',
          'price': null,
          'payment': 0.0,
          'advance': amount,
          'due': 0.0,
          'owed': amount,
        });
      } else {
        // payment
        final amount = (t['amount'] as num).toDouble();
        owed += amount;
        rows.add({
          'id': t['id'],
          'date': t['date'],
          'production': 0.0,
          'qty': null,
          'category': '—',
          'price': null,
          'payment': amount,
          'advance': 0.0,
          'due': 0.0,
          'owed': amount,
        });
      }
    }

    setState(() {
      _employee = employee;
      _rows = rows.reversed.toList(); // الأحدث أولًا
      _totalDue = due;
      _totalOwed = owed;
    });
  }

  Future<void> _deleteTransaction(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('employee_transactions', where: 'id = ?', whereArgs: [id]);
    _loadData();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTransactionSheet(
        employeeId: widget.employeeId,
        themeColor: themeColor,
        onSaved: _loadData,
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '—';
    if (v is double) {
      return v == 0 ? '—' : v.toStringAsFixed(1);
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_employee == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double balance = _totalDue - _totalOwed;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(_employee!['name'] ?? '', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // بطاقة معلومات الموظف
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: themeColor.withOpacity(0.15),
                  backgroundImage: _employee!['photoPath'] != null
                      ? FileImage(File(_employee!['photoPath']))
                      : null,
                  child: _employee!['photoPath'] == null
                      ? Icon(Icons.person, color: themeColor, size: 28)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_employee!['name'] ?? '',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(_employee!['phone'] ?? '—',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ملخص له / عليه / الرصيد
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryBox('له', _totalDue, const Color(0xFF2E7D74)),
                _summaryBox('عليه', _totalOwed, const Color(0xFFA13D3D)),
                _summaryBox('الرصيد', balance, balance >= 0 ? const Color(0xFF2E7D74) : const Color(0xFFA13D3D)),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('↔ اسحب الجدول يمين/يسار لعرض كل الأعمدة', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ),
          ),
          const SizedBox(height: 6),

          // الجدول القابل للتمرير أفقيًا
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(themeColor.withOpacity(0.1)),
                  columnSpacing: 18,
                  columns: const [
                    DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('الإنتاج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('العدد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('الصرف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('السلف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('له', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2E7D74)))),
                    DataColumn(label: Text('عليه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFA13D3D)))),
                    DataColumn(label: Text('')),
                  ],
                  rows: _rows.map((r) {
                    return DataRow(cells: [
                      DataCell(Text(r['date'].toString().substring(0, 10), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(_fmt(r['production']), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(_fmt(r['qty']), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(r['category'] ?? '—', style: const TextStyle(fontSize: 11))),
                      DataCell(Text(_fmt(r['price']), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(_fmt(r['payment']), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(_fmt(r['advance']), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(_fmt(r['due']),
                          style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D74), fontWeight: FontWeight.bold))),
                      DataCell(Text(_fmt(r['owed']),
                          style: const TextStyle(fontSize: 11, color: Color(0xFFA13D3D), fontWeight: FontWeight.bold))),
                      DataCell(IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                        onPressed: () => _deleteTransaction(r['id']),
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: themeColor,
        onPressed: _openAddSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _summaryBox(String label, double value, Color color) {
    return Column(
      children: [
        Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _AddTransactionSheet extends StatefulWidget {
  final int employeeId;
  final Color themeColor;
  final VoidCallback onSaved;

  const _AddTransactionSheet({
    required this.employeeId,
    required this.themeColor,
    required this.onSaved,
  });

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  String _type = 'production';
  final _quantityController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  Future<void> _save() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.insert('employee_transactions', {
      'employeeId': widget.employeeId,
      'type': _type,
      'quantity': double.tryParse(_quantityController.text.trim()) ?? 0,
      'amount': double.tryParse(_amountController.text.trim()) ?? 0,
      'note': _noteController.text.trim(),
      'date': now,
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
                'إضافة حركة جديدة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.themeColor),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('إنتاج'),
                    selected: _type == 'production',
                    onSelected: (_) => setState(() => _type = 'production'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('سلفة'),
                    selected: _type == 'advance',
                    onSelected: (_) => setState(() => _type = 'advance'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('صرف'),
                    selected: _type == 'payment',
                    onSelected: (_) => setState(() => _type = 'payment'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_type == 'production')
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'العدد'),
                keyboardType: TextInputType.number,
              )
            else
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'المبلغ'),
                keyboardType: TextInputType.number,
              ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _save,
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
