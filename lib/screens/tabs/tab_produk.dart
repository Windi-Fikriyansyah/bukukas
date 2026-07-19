import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../providers/app_provider.dart';
import '../../models/product_model.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:flutter/services.dart';

class TabProduk extends StatefulWidget {
  const TabProduk({super.key});

  @override
  State<TabProduk> createState() => _TabProdukState();
}

class _TabProdukState extends State<TabProduk> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _modalCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  static const platform = MethodChannel('com.example.bukukas/beep');

  void _addProduct() {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final modal = double.tryParse(_modalCtrl.text) ?? 0;
    final category = _catCtrl.text.trim().isEmpty ? 'Lainnya' : _catCtrl.text.trim();
    final barcode = _barcodeCtrl.text.trim();

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi nama dan harga jual yang valid.'), backgroundColor: AppColors.red));
      return;
    }

    if (modal < 0 || modal > price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modal tidak boleh lebih besar dari harga jual.'), backgroundColor: AppColors.red));
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    if (barcode.isNotEmpty) {
      final exists = provider.products.any((p) => p.barcode == barcode);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SKU/Barcode sudah terdaftar pada produk lain.'), backgroundColor: AppColors.red));
        return;
      }
    }

    final prod = ProductModel(
      name: name,
      price: price,
      modal: modal,
      category: category,
      barcode: barcode.isEmpty ? null : barcode,
    );

    provider.addProduct(prod);

    _nameCtrl.clear();
    _priceCtrl.clear();
    _modalCtrl.clear();
    _catCtrl.clear();
    _barcodeCtrl.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk berhasil disimpan!'), backgroundColor: AppColors.green),
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
          ),
        ),
      ),
    );
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            _buildSectionTitle('TAMBAH PRODUK'),
            const Text('NAMA PRODUK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 5),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'mis. Kopi Susu'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HARGA JUAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '8000'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MODAL (OPSIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _modalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '5000'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('KATEGORI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 5),
            TextField(
              controller: _catCtrl,
              decoration: const InputDecoration(hintText: 'mis. Minuman'),
            ),
            const SizedBox(height: 14),
            const Text('SKU / BARCODE (OPSIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 5),
            TextField(
              controller: _barcodeCtrl,
              decoration: InputDecoration(
                hintText: 'Scan atau ketik kode',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: AppColors.ink),
                  onPressed: () async {
                    String? res = await SimpleBarcodeScanner.scanBarcode(
                      context,
                      lineColor: '#1F6F54',
                      cancelButtonText: 'Batal',
                      isShowFlashIcon: true,
                    );
                    if (res is String && res != '-1' && res.isNotEmpty) {
                      try {
                        platform.invokeMethod('playBeep');
                      } catch (_) {}
                      HapticFeedback.vibrate();
                      setState(() {
                        _barcodeCtrl.text = res;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Modal boleh dikosongkan kalau belum tau — laba nanti dihitung dari harga jual penuh.',
              style: TextStyle(fontSize: 13, color: AppColors.inkSoft, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addProduct,
              child: const Text('+ Simpan Produk'),
            ),

            const SizedBox(height: 22),
            _buildSectionTitle('DAFTAR PRODUK'),
            Consumer<AppProvider>(
              builder: (context, provider, child) {
                final products = provider.products;
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('Belum ada produk tersimpan.',
                      style: TextStyle(fontSize: 13, color: AppColors.inkSoft, fontStyle: FontStyle.italic),
                    ),
                  );
                }

                return Column(
                  children: products.map((p) {
                    final modal = p.modal;
                    final margin = p.price - modal;
                    final hasModal = modal > 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink)),
                                    const SizedBox(width: 8),
                                    Text(p.category, style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasModal
                                    ? 'Jual ${Utils.formatRupiah(p.price)} · Modal ${Utils.formatRupiah(modal)} · Untung ${Utils.formatRupiah(margin)}/pcs'
                                    : 'Jual ${Utils.formatRupiah(p.price)} · Modal belum diisi',
                                  style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.inkSoft),
                                ),
                                if (p.barcode != null && p.barcode!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.qr_code, size: 12, color: AppColors.inkSoft),
                                        const SizedBox(width: 4),
                                        Text(p.barcode!, style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.inkSoft)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.red, size: 20),
                            onPressed: () {
                              if (p.id != null) provider.deleteProduct(p.id!);
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
