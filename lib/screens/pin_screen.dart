import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../providers/app_provider.dart';
import 'main_screen.dart';

class PinScreen extends StatefulWidget {
  final bool isCreateMode;
  
  const PinScreen({super.key, required this.isCreateMode});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorText = '';

  void _onKeyPressed(String value) {
    setState(() {
      _errorText = '';
      if (_pin.length < 6) {
        _pin += value;
        if (_pin.length == 6) {
          _processPin();
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorText = '';
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  void _processPin() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    if (widget.isCreateMode) {
      if (!_isConfirming) {
        // Pindah ke mode konfirmasi
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _isConfirming = true;
        });
      } else {
        // Cek apakah sama dengan confirm pin
        if (_pin == _confirmPin) {
          await provider.saveSettings(provider.shopName, true, _pin);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          }
        } else {
          setState(() {
            _errorText = 'PIN tidak cocok. Silakan ulangi.';
            _pin = '';
            _confirmPin = '';
            _isConfirming = false;
          });
        }
      }
    } else {
      // Mode verifikasi
      if (_pin == provider.pinCode) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else {
        setState(() {
          _errorText = 'PIN salah!';
          _pin = '';
        });
      }
    }
  }

  Widget _buildNumpadButton(String value) {
    return Expanded(
      child: InkWell(
        onTap: () => _onKeyPressed(value),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          height: 70,
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool isFilled = index < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.green : AppColors.paperAlt,
            border: Border.all(
              color: isFilled ? AppColors.green : AppColors.lineStrong,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.isCreateMode
        ? (_isConfirming ? 'Konfirmasi PIN Anda' : 'Buat PIN 6 Angka')
        : 'Masukkan PIN Anda';
    
    String subtitle = widget.isCreateMode
        ? (_isConfirming ? 'Masukkan kembali PIN yang baru Anda buat.' : 'PIN ini akan digunakan setiap membuka aplikasi.')
        : 'Silakan masukkan 6 angka PIN Anda.';

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: AppColors.gold, size: 28),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.fraunces(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSoft,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildDots(),
            const SizedBox(height: 16),
            SizedBox(
              height: 20,
              child: Text(
                _errorText,
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              decoration: const BoxDecoration(
                color: AppColors.paperAlt,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildNumpadButton('1'),
                      _buildNumpadButton('2'),
                      _buildNumpadButton('3'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNumpadButton('4'),
                      _buildNumpadButton('5'),
                      _buildNumpadButton('6'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNumpadButton('7'),
                      _buildNumpadButton('8'),
                      _buildNumpadButton('9'),
                    ],
                  ),
                  Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      _buildNumpadButton('0'),
                      Expanded(
                        child: InkWell(
                          onTap: _onBackspace,
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            height: 70,
                            alignment: Alignment.center,
                            child: const Icon(Icons.backspace_outlined, size: 26, color: AppColors.inkSoft),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
