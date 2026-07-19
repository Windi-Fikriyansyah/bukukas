import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Sen';
      case 2: return 'Sel';
      case 3: return 'Rab';
      case 4: return 'Kam';
      case 5: return 'Jum';
      case 6: return 'Sab';
      case 7: return 'Min';
      default: return '';
    }
  }

  Future<void> _exportCSV(List<TransactionModel> transactions) async {
    List<List<dynamic>> rows = [];
    rows.add(["Tanggal", "Waktu", "Judul", "Kategori", "Tipe", "Jumlah", "Modal"]);
    for (var t in transactions) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(t.date),
        DateFormat('HH:mm').format(t.date),
        t.title,
        t.category,
        t.type,
        t.amount,
        t.modal
      ]);
    }
    String csvString = csv.encode(rows);
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/Laporan_BukuKas_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
    final file = File(path);
    await file.writeAsString(csvString);
    await Share.shareXFiles([XFile(path)], text: 'Laporan BukuKas');
  }

  Widget _buildChart(AppProvider provider) {
    final baseDate = _selectedDate;
    List<BarChartGroupData> barGroups = [];
    
    double maxY = 0;
    
    for (int i = 0; i < 7; i++) {
      final date = baseDate.subtract(Duration(days: 6 - i));
      double sumMasuk = 0;
      double sumKeluar = 0;
      
      for (var t in provider.transactions) {
        if (t.date.year == date.year && t.date.month == date.month && t.date.day == date.day) {
          if (t.type == 'masuk') sumMasuk += t.amount;
          else sumKeluar += t.amount;
        }
      }
      
      if (sumMasuk > maxY) maxY = sumMasuk;
      if (sumKeluar > maxY) maxY = sumKeluar;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sumMasuk,
              color: AppColors.green,
              width: 8,
              borderRadius: BorderRadius.circular(2),
            ),
            BarChartRodData(
              toY: sumKeluar,
              color: AppColors.red,
              width: 8,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }
    
    if (maxY == 0) maxY = 10000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppColors.ink,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                Utils.formatRupiah(rod.toY),
                const TextStyle(color: AppColors.paper, fontSize: 10, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY == 0 ? 1 : maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: AppColors.line, strokeWidth: 1, dashArray: [4, 4]);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                String text = '';
                if (value >= 1000000) {
                  text = '${(value / 1000000).toStringAsFixed(1).replaceAll('.0', '')}jt';
                } else if (value >= 1000) {
                  text = '${(value / 1000).toStringAsFixed(0)}rb';
                } else {
                  text = value.toStringAsFixed(0);
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Text(
                    text,
                    style: GoogleFonts.spaceMono(fontSize: 9, color: AppColors.inkSoft),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index > 6) return const SizedBox();
                final date = baseDate.subtract(Duration(days: 6 - index));
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _getDayName(date.weekday),
                    style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.inkSoft),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
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
                    
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _exportCSV(filteredTrx),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export CSV Periode Ini'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.inkSoft,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.lineStrong, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TREN 7 HARI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            const Text('Masuk', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                            const SizedBox(width: 10),
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            const Text('Keluar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.line, thickness: 1, height: 12),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 200,
                      child: _buildChart(provider),
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
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Transaksi?'),
            content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal', style: TextStyle(color: AppColors.inkSoft)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
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
