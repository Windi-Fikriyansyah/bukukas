import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';
import '../models/debt_model.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bukukas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 3, // version up for barcode
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    // Transactions Table
    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  title $textType,
  amount $realType,
  modal $realType,
  type $textType,
  category $textType,
  date $textType
)
''');

    // Products Table
    await db.execute('''
CREATE TABLE products (
  id $idType,
  name $textType,
  price $realType,
  modal $realType,
  category $textType,
  barcode $textNullable
)
''');

    // Debts Table
    await db.execute('''
CREATE TABLE debts (
  id $idType,
  name $textType,
  amount $realType,
  type $textType,
  note $textType,
  date $textType,
  dueDate $textNullable,
  isPaid $intType,
  paidDate $textNullable
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Recreate DB for simplicity during development since this is a fresh setup anyway
      await db.execute('DROP TABLE IF EXISTS transactions');
      await _createDB(db, newVersion);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
    }
  }

  // ================= TRANSACTION CRUD =================
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ================= PRODUCT CRUD =================
  Future<int> insertProduct(ProductModel product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<ProductModel>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => ProductModel.fromMap(json)).toList();
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ================= DEBT CRUD =================
  Future<int> insertDebt(DebtModel debt) async {
    final db = await instance.database;
    return await db.insert('debts', debt.toMap());
  }

  Future<List<DebtModel>> getAllDebts() async {
    final db = await instance.database;
    final result = await db.query('debts', orderBy: 'date DESC');
    return result.map((json) => DebtModel.fromMap(json)).toList();
  }

  Future<int> updateDebt(DebtModel debt) async {
    final db = await instance.database;
    return await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<int> deleteDebt(int id) async {
    final db = await instance.database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }
}
