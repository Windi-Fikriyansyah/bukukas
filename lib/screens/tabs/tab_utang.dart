import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../providers/app_provider.dart';
import '../../models/debt_model.dart';
import '../../models/product_model.dart';

class _SelectedProduct {
  final ProductModel product;
  int quantity;
  _SelectedProduct(this.product, this.quantity);
}

class TabUtang extends StatefulWidget {
  const TabUtang({super.key});

  @override
  State<TabUtang> createState() => _TabUtangState();
}

class _TabUtangState extends State<TabUtang> with SingleTickerProviderStateMixin {
  bool _isPiutang = true; // true = Piutang Pelanggan, false = Utang Supplier

  // Controllers
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _dueDate;
  
  List<_SelectedProduct> _selectedProducts = [];

  late AnimationController _stampController;
  late Animation<double> _stampScale;
  late Animation<double> _stampOpacity;

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
  }

  @override
  void dispose() {
    _stampController.dispose();
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _showStempelAnimation() async {
    _stampController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      _stampController.reverse();
    }
  }

  Future<void> _addDebt() async {
    final name = _nameCtrl.text.trim();
    double amount = double.tryParse(_amountCtrl.text) ?? 0;
    final note = _noteCtrl.text.trim();

    String? productName;
    double? productModal;

    if (_isPiutang && _selectedProducts.isNotEmpty) {
      productName = _selectedProducts.map((e) => '${e.quantity}x ${e.product.name}').join(', ');
      productModal = _selectedProducts.fold<double>(0.0, (sum, e) => sum + (e.product.modal * e.quantity));
      
      // Jika amount kosong atau 0, otomatis isi dengan total harga jual
      if (amount <= 0) {
        amount = _selectedProducts.fold<double>(0.0, (sum, e) => sum + (e.product.price * e.quantity));
      }
    }

    if (name.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi nama dan jumlah yang valid.')));
      return;
    }

    final debt = DebtModel(
      name: name,
      amount: amount,
      type: _isPiutang ? 'piutang' : 'supplier',
      note: note,
      date: DateTime.now(),
      dueDate: !_isPiutang ? _dueDate : null,
      productName: productName,
      productModal: productModal,
    );

    try {
      await Provider.of<AppProvider>(context, listen: false).addDebt(debt);

      if (mounted) {
        _nameCtrl.clear();
        _amountCtrl.clear();
        _amountCtrl.clear();
        _noteCtrl.clear();
        setState(() {
          _dueDate = null;
          _selectedProducts.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isPiutang ? 'Piutang dicatat' : 'Utang Supplier dicatat'), backgroundColor: AppColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _showProductPicker(AppProvider provider) {
    List<_SelectedProduct> tempSelected = List.from(_selectedProducts);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: AppColors.lineStrong, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Text('Pilih Barang yang Diutang', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: provider.products.isEmpty
                        ? const Center(child: Text('Belum ada produk.'))
                        : ListView.builder(
                            itemCount: provider.products.length,
                            itemBuilder: (context, index) {
                              final p = provider.products[index];
                              final selectedIdx = tempSelected.indexWhere((e) => e.product.id == p.id);
                              final qty = selectedIdx >= 0 ? tempSelected[selectedIdx].quantity : 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.line),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                          Text(Utils.formatRupiah(p.price), style: const TextStyle(color: AppColors.green, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    if (qty == 0)
                                      ElevatedButton(
                                        onPressed: () {
                                          setStateModal(() {
                                            tempSelected.add(_SelectedProduct(p, 1));
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.ink,
                                          minimumSize: const Size(60, 36),
                                        ),
                                        child: const Text('Tambah'),
                                      )
                                    else
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              setStateModal(() {
                                                if (qty > 1) {
                                                  tempSelected[selectedIdx].quantity--;
                                                } else {
                                                  tempSelected.removeAt(selectedIdx);
                                                }
                                              });
                                            },
                                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.inkSoft),
                                          ),
                                          Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                          IconButton(
                                            onPressed: () {
                                              setStateModal(() {
                                                tempSelected[selectedIdx].quantity++;
                                              });
                                            },
                                            icon: const Icon(Icons.add_circle_outline, color: AppColors.green),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedProducts = tempSelected;
                        if (_selectedProducts.isNotEmpty) {
                          final totalHarga = _selectedProducts.fold(0.0, (sum, e) => sum + (e.product.price * e.quantity));
                          _amountCtrl.text = totalHarga.toInt().toString();
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Selesai Memilih'),
                  ),
                ],
              ),
            );
          },
        );
      },
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
        decoration: const BoxDecoration(color: AppColors.paper),
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
                      onTap: () => setState(() => _isPiutang = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _isPiutang ? AppColors.green : AppColors.paper,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Piutang Pelanggan',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _isPiutang ? AppColors.paper : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPiutang = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: !_isPiutang ? AppColors.red : AppColors.paper,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Utang Supplier',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: !_isPiutang ? AppColors.paper : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Consumer<AppProvider>(
              builder: (context, provider, child) {
                final debts = provider.debts.where((d) => d.type == (_isPiutang ? 'piutang' : 'supplier')).toList();
                final unpaid = debts.where((d) => !d.isPaid).toList();
                final paid = debts.where((d) => d.isPaid).toList();

                final totalUnpaid = unpaid.fold(0.0, (sum, d) => sum + d.amount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.paperAlt,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isPiutang ? 'TOTAL BELUM DITERIMA' : 'TOTAL BELUM DIBAYAR', 
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft, letterSpacing: 0.5)),
                          const SizedBox(height: 3),
                          Text(Utils.formatRupiah(totalUnpaid), 
                            style: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.red)),
                        ],
                      ),
                    ),
                    
                    _buildSectionTitle(_isPiutang ? 'CATAT PIUTANG' : 'CATAT UTANG SUPPLIER'),
                    Text(_isPiutang ? 'NAMA PELANGGAN' : 'NAMA SUPPLIER', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(hintText: _isPiutang ? 'mis. Bu Sari' : 'mis. Agen Beras Pak Joko'),
                    ),
                    const SizedBox(height: 14),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('JUMLAH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                              const SizedBox(height: 5),
                              TextField(
                                controller: _amountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(hintText: '25000'),
                              ),
                            ],
                          ),
                        ),
                        if (!_isPiutang) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('JATUH TEMPO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                                const SizedBox(height: 5),
                                InkWell(
                                  onTap: _pickDueDate,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: AppColors.paper,
                                      border: Border.all(color: AppColors.lineStrong, width: 1.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _dueDate != null ? DateFormat('dd MMM yyyy').format(_dueDate!) : 'Pilih Tanggal',
                                      style: TextStyle(color: _dueDate != null ? AppColors.ink : AppColors.inkSoft),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_isPiutang) ...[
                      const SizedBox(height: 14),
                      const Text('PILIH BARANG (OPSIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                      const SizedBox(height: 5),
                      InkWell(
                        onTap: () => _showProductPicker(provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.lineStrong, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedProducts.isEmpty
                                      ? 'Pilih produk yang diutang...'
                                      : _selectedProducts.map((e) => '${e.quantity}x ${e.product.name}').join(', '),
                                  style: TextStyle(
                                    color: _selectedProducts.isEmpty ? AppColors.inkSoft : AppColors.ink,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.shopping_bag_outlined, color: AppColors.inkSoft, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Text('CATATAN (OPSIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _noteCtrl,
                      decoration: InputDecoration(hintText: _isPiutang ? 'mis. beli sembako' : 'mis. stok beras 2 karung'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addDebt,
                      style: ElevatedButton.styleFrom(backgroundColor: _isPiutang ? AppColors.ink : AppColors.red),
                      child: Text(_isPiutang ? '+ Catat Piutang' : '+ Catat Utang Supplier'),
                    ),

                    const SizedBox(height: 10),
                    _buildSectionTitle(_isPiutang ? 'BELUM DITERIMA' : 'BELUM DIBAYAR'),
                    if (unpaid.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 10),
                        child: Text('Tidak ada utang yang belum lunas. Mantap!', style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, fontStyle: FontStyle.italic)),
                      )
                    else
                      ...unpaid.map((d) {
                        return _buildDebtCard(d, provider, false);
                      }),
                      
                    const SizedBox(height: 10),
                    _buildSectionTitle(_isPiutang ? 'SUDAH DITERIMA' : 'SUDAH DIBAYAR'),
                    if (paid.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Belum ada riwayat pelunasan.', style: TextStyle(fontSize: 13, color: AppColors.inkSoft, fontStyle: FontStyle.italic)),
                      )
                    else
                      ...paid.map((d) {
                        return _buildDebtCard(d, provider, true);
                      }),
                  ],
                );
              },
            ),
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

  Widget _buildDebtCard(DebtModel d, AppProvider provider, bool isPaid) {
    final tglStr = DateFormat('d MMM yyyy').format(isPaid ? (d.paidDate ?? d.date) : d.date);
    final isOverdue = !_isPiutang && d.dueDate != null && d.dueDate!.isBefore(DateTime.now()) && !isPaid;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      isPaid ? 'Lunas $tglStr' : '$tglStr${d.note.isNotEmpty ? ' · ${d.note}' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                    ),
                    if (d.productName != null && d.productName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Barang: ${d.productName}',
                          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, fontStyle: FontStyle.italic),
                        ),
                      ),
                    const SizedBox(height: 6),
                    if (isPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0x1F1F6F54), borderRadius: BorderRadius.circular(10)),
                        child: const Text('LUNAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 0.5)),
                      )
                    else if (_isPiutang)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0x1EB23A2E), borderRadius: BorderRadius.circular(10)),
                        child: const Text('BELUM LUNAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red, letterSpacing: 0.5)),
                      )
                    else ...[
                      if (d.dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: isOverdue ? const Color(0x2EB23A2E) : const Color(0x26C08A28), borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            isOverdue ? 'LEWAT TEMPO · ${DateFormat('d MMM yyyy').format(d.dueDate!)}' : 'TEMPO ${DateFormat('d MMM yyyy').format(d.dueDate!)}', 
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isOverdue ? AppColors.red : AppColors.gold, letterSpacing: 0.5)
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0x1EB23A2E), borderRadius: BorderRadius.circular(10)),
                          child: const Text('BELUM DIBAYAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red, letterSpacing: 0.5)),
                        ),
                    ],
                  ],
                ),
              ),
              Text(
                Utils.formatRupiah(d.amount),
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isPaid ? AppColors.green : AppColors.red,
                ),
              ),
            ],
          ),
          if (!isPaid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.payDebt(d);
                        _showStempelAnimation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      ),
                      child: Text(_isPiutang ? 'Tandai Lunas' : 'Tandai Dibayar', style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (d.id != null) provider.deleteDebt(d.id!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.inkSoft,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7), side: const BorderSide(color: AppColors.lineStrong)),
                      ),
                      child: const Text('Hapus', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
