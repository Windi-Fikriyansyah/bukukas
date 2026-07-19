import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/app_colors.dart';
import '../models/product_model.dart';

class ScannerPage extends StatefulWidget {
  final List<ProductModel> products;
  final Function(ProductModel) onProductFound;
  
  const ScannerPage({Key? key, required this.products, required this.onProductFound}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController cameraController = MobileScannerController();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  bool isProcessing = false;
  static const platform = MethodChannel('com.example.bukukas/beep');

  void _onDetect(BarcodeCapture capture) {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          isProcessing = true;
        });

        final sku = barcode.rawValue!;
        
        final matchedProduct = widget.products.where((p) => p.barcode == sku).firstOrNull;

        if (matchedProduct != null) {
          try {
            platform.invokeMethod('playBeep');
          } catch (_) {}
          HapticFeedback.vibrate();

          // Tambahkan ke keranjang via callback
          widget.onProductFound(matchedProduct);

          // Tampilkan alert di dalam halaman scanner menggunakan local key
          scaffoldMessengerKey.currentState?.clearSnackBars();
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('${matchedProduct.name} ditambahkan ke keranjang!'),
              backgroundColor: AppColors.green,
              duration: const Duration(milliseconds: 1000),
            ),
          );
          
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() {
                isProcessing = false;
              });
            }
          });
        } else {
          scaffoldMessengerKey.currentState?.clearSnackBars();
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Produk dengan SKU $sku tidak ditemukan'),
              backgroundColor: AppColors.red,
              duration: const Duration(milliseconds: 1000),
            ),
          );
          
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() {
                isProcessing = false;
              });
            }
          });
        }
        break; 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Barcode', style: TextStyle(color: AppColors.ink)),
          backgroundColor: AppColors.paper,
          iconTheme: const IconThemeData(color: AppColors.ink),
          elevation: 0,
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: cameraController,
              onDetect: _onDetect,
            ),
          ],
        ),
      ),
    );
  }
}
