import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../providers/app_provider.dart';
import '../../models/transaction_model.dart';
import '../scanner_page.dart';
import 'package:flutter/services.dart';


class CartItem {
  final String name;
  final double price;
  final double modal;
  final String category;
  int qty;

  CartItem({
    required this.name,
    required this.price,
    this.modal = 0,
    this.category = '',
    this.qty = 1,
  });
}

class TabCatat extends StatefulWidget {
  const TabCatat({super.key});

  @override
  State<TabCatat> createState() => _TabCatatState();
}

class _TabCatatState extends State<TabCatat> with SingleTickerProviderStateMixin {
  bool _isMasuk = true;
  String _activeCategory = 'Semua';
  final List<CartItem> _cart = [];
  String _searchQuery = '';
  static const platform = MethodChannel('com.example.bukukas/beep');

  late AnimationController _stampController;
  late Animation<double> _stampScale;
  late Animation<double> _stampOpacity;

  // Manual Input Controllers
  final _manualNameCtrl = TextEditingController();
  final _manualPriceCtrl = TextEditingController();
  
  // Expense Controllers
  final _expenseNameCtrl = TextEditingController();
  final _expenseAmountCtrl = TextEditingController();
  final _expenseNoteCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _stampScale = Tween<double>(begin: 2.2, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.easeOutBack),
    );
    _stampOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.easeIn),
    );
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text;
      });
    });
  }

  @override
  void dispose() {
    _stampController.dispose();
    _manualNameCtrl.dispose();
    _manualPriceCtrl.dispose();
    _expenseNameCtrl.dispose();
    _expenseAmountCtrl.dispose();
    _expenseNoteCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showStempelAnimation() async {
    _stampController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      _stampController.reverse();
    }
  }

  void _addToCart(String name, double price, double modal, String category) {
    final idx = _cart.indexWhere((i) => i.name == name && i.price == price && i.modal == modal);
    setState(() {
      if (idx >= 0) {
        _cart[idx].qty++;
      } else {
        _cart.add(CartItem(name: name, price: price, modal: modal, category: category));
      }
    });
  }

  void _updateCartQty(int index, int delta) {
    setState(() {
      _cart[index].qty += delta;
      if (_cart[index].qty <= 0) {
        _cart.removeAt(index);
      }
    });
  }

  void _catatMasuk() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong.')));
      return;
    }
    double totalAmount = 0;
    double totalModal = 0;
    String category = _cart.first.category;
    List<String> itemNames = [];

    for (var item in _cart) {
      totalAmount += item.price * item.qty;
      totalModal += item.modal * item.qty;
      itemNames.add(item.qty > 1 ? '${item.name} x${item.qty}' : item.name);
    }

    final trx = TransactionModel(
      title: itemNames.join(', '),
      amount: totalAmount,
      modal: totalModal,
      type: 'masuk',
      category: category,
      date: DateTime.now(),
    );

    Provider.of<AppProvider>(context, listen: false).addTransaction(trx);
    
    setState(() {
      _cart.clear();
    });
    
    _showStempelAnimation();
  }

  void _catatKeluar() {
    final name = _expenseNameCtrl.text.trim();
    final amount = double.tryParse(_expenseAmountCtrl.text) ?? 0;
    final note = _expenseNoteCtrl.text.trim();

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi keperluan dan jumlah yang valid.')));
      return;
    }

    final trx = TransactionModel(
      title: note.isNotEmpty ? '$name — $note' : name,
      amount: amount,
      modal: 0,
      type: 'keluar',
      category: 'Pengeluaran',
      date: DateTime.now(),
    );

    Provider.of<AppProvider>(context, listen: false).addTransaction(trx);
    
    setState(() {
      _expenseNameCtrl.clear();
      _expenseAmountCtrl.clear();
      _expenseNoteCtrl.clear();
    });
    
    _showStempelAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: const BoxDecoration(
          color: AppColors.paper,
        ),
        child: Stack(
          children: [
            ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            // Toggle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.ink, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMasuk = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _isMasuk ? AppColors.green : AppColors.paper,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '↑ Uang Masuk',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _isMasuk ? AppColors.paper : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMasuk = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: !_isMasuk ? AppColors.red : AppColors.paper,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '↓ Uang Keluar',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: !_isMasuk ? AppColors.paper : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            
            if (_isMasuk) _buildPanelMasuk() else _buildPanelKeluar(),
          ],
        ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _stampController,
                  builder: (context, child) {
                    if (_stampController.value == 0) return const SizedBox.shrink();
                    return Container(
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: _stampOpacity.value,
                        child: Transform.scale(
                          scale: _stampScale.value,
                          child: Transform.rotate(
                            angle: -0.174533, // -10 degrees
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.red, width: 5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'LUNAS',
                                style: GoogleFonts.fraunces(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 32,
                                  letterSpacing: 3,
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 16),
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: Text(
          title,
          style: GoogleFonts.fraunces(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
            letterSpacing: 1,
          ).copyWith(textBaseline: TextBaseline.alphabetic),
        ),
      ),
    );
  }

  Widget _buildPanelMasuk() {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final products = provider.products;
        final categories = ['Semua', ...products.map((p) => p.category.trim().isNotEmpty ? p.category : 'Lainnya').toSet()];
        final filteredProducts = products.where((p) {
          if (_activeCategory != 'Semua') {
            final cat = p.category.trim().isNotEmpty ? p.category : 'Lainnya';
            if (cat != _activeCategory) return false;
          }
          if (_searchQuery.isNotEmpty) {
            return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('PILIH PRODUK'),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari produk atau scan...',
                prefixIcon: const Icon(Icons.search, color: AppColors.inkSoft),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.ink),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScannerPage(
                          products: products,
                          onProductFound: (product) {
                            _addToCart(product.name, product.price, product.modal, product.category);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isActive = _activeCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 12),
                    child: InkWell(
                      onTap: () => setState(() => _activeCategory = cat),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.ink : Colors.transparent,
                          border: Border.all(color: isActive ? AppColors.ink : AppColors.lineStrong),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppColors.paper : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Product Chips
            if (filteredProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Text('Belum ada produk. Tambah dulu di tab Produk, atau isi manual di bawah.',
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft, fontStyle: FontStyle.italic),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filteredProducts.map((p) {
                  return InkWell(
                    onTap: () => _addToCart(p.name, p.price, p.modal, p.category),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.paperAlt,
                        border: Border.all(color: AppColors.lineStrong),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                          const SizedBox(width: 5),
                          Text(Utils.formatRupiah(p.price), style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
            _buildSectionTitle('ATAU ISI MANUAL'),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NAMA BARANG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _manualNameCtrl,
                        decoration: const InputDecoration(hintText: 'mis. Es Teh'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HARGA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _manualPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '5000'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final name = _manualNameCtrl.text.trim();
                final price = double.tryParse(_manualPriceCtrl.text) ?? 0;
                if (name.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi nama dan harga valid')));
                  return;
                }
                _addToCart(name, price, 0, 'Lainnya');
                _manualNameCtrl.clear();
                _manualPriceCtrl.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.inkSoft,
                elevation: 0,
                side: const BorderSide(color: AppColors.lineStrong, width: 1.5, style: BorderStyle.solid), // Dashed border not easy natively, solid is fine
              ),
              child: const Text('+ Tambah ke Keranjang'),
            ),
            
            // Cart Section
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.lineStrong, width: 1)), // Dashed in CSS, solid in flutter
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('KERANJANG'),
                  ...List.generate(_cart.length, (index) {
                    final item = _cart[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _updateCartQty(index, -1),
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.ink)),
                                  alignment: Alignment.center,
                                  child: const Text('−', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${item.qty}'),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _updateCartQty(index, 1),
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.ink)),
                                  alignment: Alignment.center,
                                  child: const Text('+', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              Utils.formatRupiah(item.price * item.qty),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.spaceMono(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  // Total
                  Padding(
                    padding: const EdgeInsets.only(top: 18, bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.lineStrong, width: 3, style: BorderStyle.solid)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Diterima', style: GoogleFonts.fraunces(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(
                            Utils.formatRupiah(_cart.fold(0.0, (sum, i) => sum + (i.price * i.qty))),
                            style: GoogleFonts.spaceMono(fontWeight: FontWeight.w700, fontSize: 22, color: AppColors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  ElevatedButton(
                    onPressed: _catatMasuk,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                    child: const Text('Catat Transaksi'),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildPanelKeluar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('CATAT PENGELUARAN'),
        const Text('UNTUK APA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
        const SizedBox(height: 5),
        TextField(
          controller: _expenseNameCtrl,
          decoration: const InputDecoration(hintText: 'mis. Beli galon air'),
        ),
        const SizedBox(height: 14),
        const Text('JUMLAH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
        const SizedBox(height: 5),
        TextField(
          controller: _expenseAmountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '15000'),
        ),
        const SizedBox(height: 14),
        const Text('CATATAN (OPSIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
        const SizedBox(height: 5),
        TextField(
          controller: _expenseNoteCtrl,
          decoration: const InputDecoration(hintText: 'mis. buat stok bulan ini'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _catatKeluar,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
          child: const Text('Catat Pengeluaran'),
        ),
      ],
    );
  }
}
