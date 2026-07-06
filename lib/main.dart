import 'package:flutter/material.dart';
import 'journal_capture_screen.dart';

void main() {
  runApp(const MezanApp());
}

class MezanApp extends StatelessWidget {
  const MezanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ميزان ERP',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF6F0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22303C),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_SectionItem> sections = [
      _SectionItem('الموظفون', Icons.people, const Color(0xFF2C3E67), null),
      _SectionItem('التجار', Icons.storefront, const Color(0xFF6B8E4E), null),
      _SectionItem('المحلات والبسطات', Icons.store_mall_directory, const Color(0xFFC77B3E), null),
      _SectionItem('المخزون', Icons.inventory_2, const Color(0xFF5B4B8A), null),
      _SectionItem('المصروفات', Icons.money_off, const Color(0xFFA13D3D), null),
      _SectionItem('تصوير اليومية', Icons.camera_alt, const Color(0xFFB08D57), const JournalCaptureScreen()),
      _SectionItem('التقارير', Icons.bar_chart, const Color(0xFF2E7D74), null),
      _SectionItem('المزامنة', Icons.sync, const Color(0xFF4A6572), null),
      _SectionItem('المستخدمون', Icons.person, const Color(0xFF34568B), null),
      _SectionItem('الإعدادات', Icons.settings, const Color(0xFF6E6E6E), null),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF22303C),
        title: const Text(
          'ميزان ERP',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: sections.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            return _SectionCard(section: sections[index]);
          },
        ),
      ),
    );
  }
}

class _SectionItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? destination;

  _SectionItem(this.title, this.icon, this.color, this.destination);
}

class _SectionCard extends StatelessWidget {
  final _SectionItem section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: section.color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (section.destination != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => section.destination!),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('قسم "${section.title}" قيد التطوير')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: section.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(section.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                section.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: section.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
