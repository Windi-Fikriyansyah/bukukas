import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../core/app_colors.dart';
import 'tabs/tab_catat.dart';
import 'tabs/tab_produk.dart';
import 'tabs/tab_utang.dart';
import 'tabs/tab_laporan.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const TabCatat(),
    const TabProduk(),
    const TabUtang(),
    const TabLaporan(),
  ];

  String _getFormattedDate() {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(bottom: BorderSide(color: AppColors.lineStrong, width: 3, style: BorderStyle.solid)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 14), // Added top padding for status bar manually
          child: Row(
            children: [
              Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final initial = provider.shopName.isNotEmpty ? provider.shopName[0].toUpperCase() : 'B';
                  return Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: GoogleFonts.fraunces(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.paper,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'BUKU KAS PREMIUM',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    Consumer<AppProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          provider.shopName.isNotEmpty ? provider.shopName : 'Toko Saya',
                          style: GoogleFonts.fraunces(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    Text(
                      _getFormattedDate(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _showSettingsModal,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lineStrong, width: 1.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_outlined, size: 18, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_document),
            label: 'Catat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Utang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final TextEditingController _shopNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _shopNameCtrl.text = provider.shopName;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lineStrong,
                borderRadius: BorderRadius.circular(3),
              ),
              margin: const EdgeInsets.only(bottom: 14),
            ),
          ),
          Text(
            'Pengaturan',
            style: GoogleFonts.fraunces(
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Nama Toko', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
          const SizedBox(height: 5),
          TextField(
            controller: _shopNameCtrl,
            decoration: const InputDecoration(
              hintText: 'mis. Warung Bu Sari',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final provider = Provider.of<AppProvider>(context, listen: false);
              provider.saveSettings(_shopNameCtrl.text.trim(), provider.isPinActive, provider.pinCode);
              Navigator.pop(context);
            },
            child: const Text('Simpan Pengaturan'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.inkSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
                side: const BorderSide(color: AppColors.lineStrong, style: BorderStyle.solid),
              ),
            ),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
