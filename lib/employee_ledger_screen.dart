import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'database_helper.dart';

class EmployeeLedgerScreen extends StatefulWidget {
  final Map<String, dynamic> employee;
  const EmployeeLedgerScreen({super.key, required this.employee});

  @override
  State<EmployeeLedgerScreen> createState() => _EmployeeLedgerScreenState();
}

class _EmployeeLedgerScreenState extends State<EmployeeLedgerScreen> {
  static const Color navy = Color(0xFF16345C);
  static const Color purple = Color(0xFF6E4FA3);
  static const Color green = Color(0xFF1B873F);
  static const Color red = Color(0xFFD32F2F);

  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final db = await DatabaseHelper.instance.database;
    final data = await db.query(
      'employee_ledger',
      where: 'employeeId = ?',
      whereArgs: [widget.employee['id']],
      orderBy: 'id ASC',
    );
    setState(() {
      _entries = data;
      _loading = false;
    });
  }

  double _netOf(Map<String, dynamic> e) {
    final qty = (e['quantity'] ?? 0) as num;
    final price = (e['price'] ?? 0) as num;
    final disb = (e['disbursement'] ?? 0) as num;
    final adv = (e['advance'] ?? 0) as num;
    return ((qty * price) - disb - adv).toDouble();
  }

  Map<String, double> _totals() {
    double le = 0, alayh = 0, advance = 0, disbursement = 0;
    for (final e in _entries) {
      final net = _netOf(e);
      if (net >= 0) {
        le += net;
      } else {
        alayh += net.abs();
      }
      advance += ((e['advance'] ?? 0) as num).toDouble();
      disbursement += ((e['disbursement'] ?? 0) as num).toDouble();
    }
    return {
      'le': le,
      'alayh': alayh,
      'advance': advance,
      'disbursement': disbursement,
    };
  }

  String _fmt(num v) {
    final s = v.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  String _todayStr() => DateTime.now().toIso8601String().split('T')[0];

  String _shortDate(dynamic raw) {
    final str = (raw ?? '').toString();
    if (str.isEmpty) return '-';
    return str.split('T')[0];
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddLedgerEntrySheet(
        employeeId: widget.employee['id'],
        onSaved: _loadEntries,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals();
    final balance = totals['le']! - totals['alayh']!;
    final todayCount =
        _entries.where((e) => (e['date'] ?? '').toString().startsWith(_todayStr())).length;
    final lastDate = _entries.isEmpty
        ? '-'
        : (_entries.last['date'] ?? '').toString().split('T')[0];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: navy,
        centerTitle: true,
        title: const Text('كشف حساب الموظف',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone, color: green, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            widget.employee['phone']?.toString() ?? '',
                            style: const TextStyle(
                                color: green, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        widget.employee['name']?.toString() ?? '',
                        style: const TextStyle(
                            color: navy, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: navy.withOpacity(0.1),
                        backgroundImage: widget.employee['photoPath'] != null
                            ? FileImage(File(widget.employee['photoPath']))
                            : null,
                        child: widget.employee['photoPath'] == null
                            ? const Icon(Icons.person, color: navy)
                            : null,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('لا توجد حركات بعد، اضغط + للإضافة'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Table(
                              border: TableBorder.all(color: Colors.grey.shade300),
                              columnWidths: const {
                                0: FixedColumnWidth(75),
                                1: FixedColumnWidth(75),
                                2: FixedColumnWidth(80),
                                3: FixedColumnWidth(80),
                                4: FixedColumnWidth(80),
                                5: FixedColumnWidth(65),
                                6: FixedColumnWidth(100),
                                7: FixedColumnWidth(90),
                              },
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(color: navy),
                                  children: const [
                                    _HeaderCell('عليه'),
                                    _HeaderCell('له'),
                                    _HeaderCell('السلفة'),
                                    _HeaderCell('الصرفة'),
                                    _HeaderCell('السعر'),
                                    _HeaderCell('العدد'),
                                    _HeaderCell('الصنف'),
                                    _HeaderCell('التاريخ'),
                                  ],
                                ),
                                for (final e in _entries)
                                  TableRow(
                                    children: [
                                      _DataCell(
                                        _netOf(e) < 0 ? _fmt(_netOf(e).abs()) : '—',
                                        color: red,
                                      ),
                                      _DataCell(
                                        _netOf(e) >= 0 ? _fmt(_netOf(e)) : '—',
                                        color: green,
                                      ),
                                      _DataCell(
                                        ((e['advance'] ?? 0) as num) > 0
                                            ? _fmt((e['advance'] as num))
                                            : '—',
                                      ),
                                      _DataCell(
                                        ((e['disbursement'] ?? 0) as num) > 0
                                            ? _fmt((e['disbursement'] as num))
                                            : '—',
                                      ),
                                      _DataCell(
                                        ((e['price'] ?? 0) as num) > 0
                                            ? _fmt((e['price'] as num))
                                            : '—',
                                      ),
                                      _DataCell(_fmt((e['quantity'] ?? 0) as num)),
                                      _DataCell(e['category']?.toString() ?? ''),
                                      _DataCell(_shortDate(e['date'])),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _TotalItem('إجمالي له', _fmt(totals['le']!), green),
                      _TotalItem('إجمالي عليه', _fmt(totals['alayh']!), red),
                      Column(
                        children: [
                          const Text('الرصيد الحالي',
                              style: TextStyle(color: Colors.black54, fontSize: 12)),
                          Text(
                            _fmt(balance.abs()),
                            style: const TextStyle(
                                color: navy, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            balance >= 0 ? 'له' : 'عليه',
                            style: TextStyle(
                              color: balance >= 0 ? green : red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(Icons.attach_money, 'حركات اليوم', '$todayCount'),
                      _StatItem(Icons.calendar_today, 'تاريخ آخر حركة', lastDate),
                      _StatItem(Icons.person, 'إجمالي السلف', _fmt(totals['advance']!)),
                      _StatItem(Icons.pie_chart, 'إجمالي المصروفات', _fmt(totals['disbursement']!)),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: purple,
        onPressed: _openAddSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final Color? color;
  const _DataCell(this.text, {this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TotalItem(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6E4FA3), size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label,
              style: const TextStyle(color: Colors.black45, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AddLedgerEntrySheet extends StatefulWidget {
  final int employeeId;
  final VoidCallback onSaved;
  const _AddLedgerEntrySheet({required this.employeeId, required this.onSaved});

  @override
  State<_AddLedgerEntrySheet> createState() => _AddLedgerEntrySheetState();
}

class _AddLedgerEntrySheetState extends State<_AddLedgerEntrySheet> {
  static const Color navy = Color(0xFF16345C);
  static const Color purple = Color(0xFF6E4FA3);

  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _disbursementController = TextEditingController();
  final _advanceController = TextEditingController();
  final _noteController = TextEditingController();

  Future<void> _save() async {
    if (_categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الصنف')),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;
    await db.insert('employee_ledger', {
      'employeeId': widget.employeeId,
      'category': _categoryController.text.trim(),
      'quantity': double.tryParse(_quantityController.text.trim()) ?? 0,
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'disbursement': double.tryParse(_disbursementController.text.trim()) ?? 0,
      'advance': double.tryParse(_advanceController.text.trim()) ?? 0,
      'note': _noteController.text.trim(),
      'date': DateTime.now().toIso8601String(),
    });

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  Widget _fieldLabel(String text, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, color: navy, fontSize: 14)),
        const SizedBox(width: 6),
        Icon(icon, color: purple, size: 18),
      ],
    );
  }

  InputDecoration _dec(String hint, IconData leading) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(leading, color: purple),
      filled: true,
      fillColor: const Color(0xFFF7F5FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: purple, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 18,
        right: 18,
        top: 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: navy),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text(
                  'إضافة حركة جديدة',
                  style: TextStyle(fontWeight: FontWeight.bold, color: navy, fontSize: 19),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _fieldLabel('الصنف', Icons.inventory_2_outlined),
            const SizedBox(height: 6),
            TextField(
              controller: _categoryController,
              decoration: _dec('اكتب الصنف', Icons.edit_outlined),
            ),
            const SizedBox(height: 16),

            _fieldLabel('العدد', Icons.format_list_numbered),
            const SizedBox(height: 6),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _dec('أدخل العدد', Icons.calculate_outlined),
            ),
            const SizedBox(height: 16),

            _fieldLabel('السعر', Icons.sell_outlined),
            const SizedBox(height: 6),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec('أدخل السعر', Icons.calculate_outlined),
            ),
            const SizedBox(height: 16),

            _fieldLabel('الصرفة', Icons.money_outlined),
            const SizedBox(height: 6),
            TextField(
              controller: _disbursementController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec('أدخل مبلغ الصرفة', Icons.calculate_outlined),
            ),
            const SizedBox(height: 16),

            _fieldLabel('السلفة', Icons.account_balance_wallet_outlined),
            const SizedBox(height: 6),
            TextField(
              controller: _advanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec('أدخل مبلغ السلفة', Icons.calculate_outlined),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _noteController,
              maxLength: 200,
              maxLines: 2,
              decoration: _dec('اكتب ملاحظة (اختياري)', Icons.edit_note),
            ),
            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('حفظ وترحيل',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'سيتم إضافة الحركة وحفظها مباشرة في كشف حساب الموظف',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
