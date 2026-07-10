import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mezan.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ================== الموظفون ==================
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photoPath TEXT,
        phone TEXT,
        category TEXT,
        unitPrice REAL DEFAULT 0,
        notes TEXT,
        createdAt TEXT,
        updatedAt TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE employee_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employeeId INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity REAL DEFAULT 0,
        amount REAL DEFAULT 0,
        note TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (employeeId) REFERENCES employees (id) ON DELETE CASCADE
      );
    ''');

    // ================== التجار ==================
    await db.execute('''
      CREATE TABLE merchants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photoPath TEXT,
        phone TEXT,
        city TEXT,
        relationType TEXT DEFAULT 'بضاعة',
        notes TEXT,
        createdAt TEXT,
        updatedAt TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE merchant_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchantId INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL DEFAULT 0,
        note TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (merchantId) REFERENCES merchants (id) ON DELETE CASCADE
      );
    ''');

    // ================== المحلات والبسطات ==================
    await db.execute('''
      CREATE TABLE shops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photoPath TEXT,
        location TEXT,
        manager TEXT,
        createdAt TEXT,
        updatedAt TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE shop_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopId INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL DEFAULT 0,
        note TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (shopId) REFERENCES shops (id) ON DELETE CASCADE
      );
    ''');

    // ================== المخزون ==================
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        quantity REAL DEFAULT 0,
        unit TEXT,
        minQuantityAlert REAL DEFAULT 0,
        notes TEXT,
        createdAt TEXT,
        updatedAt TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE inventory_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inventoryId INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity REAL DEFAULT 0,
        note TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (inventoryId) REFERENCES inventory (id) ON DELETE CASCADE
      );
    ''');

    // ================== المصروفات ==================
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL DEFAULT 0,
        note TEXT,
        date TEXT NOT NULL,
        createdAt TEXT
      );
    ''');

    // ================== دفاتر اليومية ==================
    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT,
        extractedText TEXT,
        status TEXT DEFAULT 'pending',
        date TEXT NOT NULL,
        createdAt TEXT
      );
    ''');

    // ================== المستخدمون ==================
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL,
        role TEXT NOT NULL,
        createdAt TEXT
      );
    ''');

    // ================== المزامنة ==================
    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableName TEXT NOT NULL,
        recordId INTEGER NOT NULL,
        status TEXT NOT NULL,
        updatedAt TEXT
      );
    ''');
  }
}
