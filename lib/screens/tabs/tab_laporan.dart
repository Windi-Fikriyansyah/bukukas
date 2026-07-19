import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../providers/app_provider.dart';
import '../../models/transaction_model.dart';

class TabLaporan extends StatefulWidget {
  const TabLaporan({super.key});

  @override
  State<TabLaporan> createState() => _TabLaporanState();
}

class _TabLaporanState extends State<TabLaporan> {
  String _periodeAktif = 'harian';
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _isTransactionInPeriod(DateTime trxDate) {
    if (_periodeAktif == 'harian') {
      return trxDate.year == _selectedDate.year &&
             trxDate.month == _selectedDate.month &&
             trxDate.day == _selectedDate.day;
    } else if (_periodeAktif == 'mingguan') {
      // Assuming week starts on Monday
      final day = _selectedDate.weekday;

      final monday = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).add(Duration(days: 1 - day));
      final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      return trxDate.isAfter(monday.subtract(const Duration(seconds: 1))) && trxDate.isBefore(sunday.add(const Duration(seconds: 1)));
    } else {
      // bulanan
      return trxDate.year == _selectedDate.year && trxDate.month == _selectedDate.month;
    }
  }

  String _getDateLabel() {
    if (_periodeAktif == 'harian') {
      return DateFormat('d MMM yyyy').format(_selectedDate);
    } else if (_periodeAktif == 'mingguan') {
      final day = _selectedDate.weekday;
      final monday = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).add(Duration(days: 1 - day));
      final sunday = monday.add(const Duration(days: 6));
      return '${DateFormat('d MMM').format(monday)} - ${DateFormat('d MMM yyyy').format(sunday)}';
    } else {
      return DateFormat('MMMM yyyy').format(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: const BoxDecoration(color: AppColors.paper),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            // Toggle Periode
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.ink, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildPeriodBtn('Harian', 'harian'),
                  _buildPeriodBtn('Mingguan', 'mingguan'),
                  _buildPeriodBtn('Bulanan', 'bulanan'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            
            // Date Picker
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.lineStrong, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_getDateLabel(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Icon(Icons.calendar_month, size: 20, color: AppColors.inkSoft),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Consumer<AppProvider>(
              builder: (context, provider, child) {
                final filteredTrx = provider.transactions.where((t) => _isTransactionInPeriod(t.date)).toList();
                
                double masuk = 0;
                double keluar = 0;
                double modal = 0;
                
                for (var t in filteredTrx) {
                  if (t.type == 'masuk') {
                    masuk += t.amount;
                    modal += t.modal;
                  } else {
                    keluar += t.amount;
                  }
                }
                
                double labaKotor = masuk - modal;
                double labaBersih = labaKotor - keluar;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      children: [
                        _buildSummaryCard('PEMASUKAN', Utils.formatRupiah(masuk), AppColors.green),
                        _buildSummaryCard('MODAL TERJUAL', Utils.formatRupiah(modal), AppColors.ink),
                        _buildSummaryCard('LABA KOTOR', Utils.formatRupiah(labaKotor), AppColors.ink),
                        _buildSummaryCard('PENGELUARAN', Utils.formatRupiah(keluar), AppColors.red),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LABA BERSIH', style: TextStyle(fontSize: 11, color: Color(0xFFC9C2B3), letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text(Utils.formatRupiah(labaBersih), style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.paper)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    const Text('RIWAYAT TRANSAKSI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                    const Divider(color: AppColors.line, thickness: 1, height: 20),
                    
                    if (filteredTrx.isEmpty)
                      const Text('Belum ada transaksi di periode ini.', style: TextStyle(fontSize: 13, color: AppColors.inkSoft, fontStyle: FontStyle.italic))
                    else
                      ...filteredTrx.map((t) => _buildTrxRow(t, provider)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodBtn(String label, String value) {
    final isOn = _periodeAktif == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _periodeAktif = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(color: isOn ? AppColors.ink : AppColors.paper),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isOn ? AppColors.paper : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paperAlt,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.spaceMono(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildTrxRow(TransactionModel t, AppProvider provider) {
    final isMasuk = t.type == 'masuk';
    return Dismissible(
      key: Key(t.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        if (t.id != null) provider.deleteTransaction(t.id!);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('${DateFormat('HH:mm').format(t.date)} · ${t.category}', style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.inkSoft)),
                ],
              ),
            ),
            Text(
              isMasuk ? Utils.formatRupiah(t.amount) : '-${Utils.formatRupiah(t.amount)}',
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isMasuk ? AppColors.green : AppColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
