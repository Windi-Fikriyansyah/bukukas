import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/transaction_model.dart';
import '../models/product_model.dart';
import '../models/debt_model.dart';

class AppProvider with ChangeNotifier {
  // Database references
  final DatabaseHelper _db = DatabaseHelper.instance;

  // State variables
  List<TransactionModel> _transactions = [];
  List<ProductModel> _products = [];
  List<DebtModel> _debts = [];
  
  // Settings
  String _shopName = 'Toko Saya';
  bool _isPinActive = false;
  String? _pinCode;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  List<ProductModel> get products => _products;
  List<DebtModel> get debts => _debts;
  
  String get shopName => _shopName;
  bool get isPinActive => _isPinActive;
  String? get pinCode => _pinCode;

  // Load Data on App Start
  Future<void> loadAllData() async {
    await _loadSettings();
    await _loadFromDb();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _shopName = prefs.getString('shopName') ?? 'Toko Saya';
    _isPinActive = prefs.getBool('isPinActive') ?? false;
    _pinCode = prefs.getString('pinCode');
    notifyListeners();
  }

  Future<void> saveSettings(String shopName, bool isPinActive, String? pinCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopName', shopName);
    await prefs.setBool('isPinActive', isPinActive);
    if (pinCode != null) {
      await prefs.setString('pinCode', pinCode);
    } else {
      await prefs.remove('pinCode');
    }
    
    _shopName = shopName;
    _isPinActive = isPinActive;
    _pinCode = pinCode;
    notifyListeners();
  }

  Future<void> _loadFromDb() async {
    _transactions = await _db.getAllTransactions();
    _products = await _db.getAllProducts();
    _debts = await _db.getAllDebts();
    notifyListeners();
  }

  // ================ TRANSACTIONS ================
  Future<void> addTransaction(TransactionModel trx) async {
    await _db.insertTransaction(trx);
    await _loadFromDb();
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    await _loadFromDb();
  }

  // ================ PRODUCTS ================
  Future<void> addProduct(ProductModel prod) async {
    await _db.insertProduct(prod);
    await _loadFromDb();
  }

  Future<void> deleteProduct(int id) async {
    await _db.deleteProduct(id);
    await _loadFromDb();
  }

  // ================ DEBTS ================
  Future<void> addDebt(DebtModel debt) async {
    await _db.insertDebt(debt);
    await _loadFromDb();
  }

  Future<void> updateDebt(DebtModel debt) async {
    await _db.updateDebt(debt);
    await _loadFromDb();
  }

  Future<void> deleteDebt(int id) async {
    await _db.deleteDebt(id);
    await _loadFromDb();
  }

  // Pay Debt: Marks as paid and creates a corresponding transaction
  Future<void> payDebt(DebtModel debt) async {
    final updatedDebt = DebtModel(
      id: debt.id,
      name: debt.name,
      amount: debt.amount,
      type: debt.type,
      note: debt.note,
      date: debt.date,
      dueDate: debt.dueDate,
      isPaid: true,
      paidDate: DateTime.now(),
    );
    await _db.updateDebt(updatedDebt);

    // Create Transaction
    final isPiutang = debt.type == 'piutang';
    String title = isPiutang ? 'Pelunasan piutang — ' : 'Bayar utang — ';
    title += debt.name;
    if (debt.productName != null && debt.productName!.isNotEmpty) {
      title += ' (${debt.productName})';
    }

    final trx = TransactionModel(
      title: title,
      amount: debt.amount,
      modal: debt.productModal ?? 0.0,
      type: isPiutang ? 'masuk' : 'keluar',
      category: isPiutang ? 'Piutang' : 'Utang Supplier',
      date: DateTime.now(),
    );
    await _db.insertTransaction(trx);
    
    await _loadFromDb();
  }
}
