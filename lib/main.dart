import 'package:flutter/material.dart';

void main() {
  runApp(MezanApp());
}

class MezanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ميزان ERP',
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ميزان ERP'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.people),
            title: Text('الموظفون'),
          ),
          ListTile(
            leading: Icon(Icons.inventory),
            title: Text('المخزون'),
          ),
          ListTile(
            leading: Icon(Icons.store),
            title: Text('التجار'),
          ),
          ListTile(
            leading: Icon(Icons.money_off),
            title: Text('المصروفات'),
          ),
          ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('التقارير'),
          ),
        ],
      ),
    );
  }
}
