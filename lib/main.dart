import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_colors.dart';
import 'core/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/main_screen.dart';
import 'screens/pin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  final appProvider = AppProvider();
  await appProvider.loadAllData();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
      ],
      child: BukuKasApp(appProvider: appProvider),
    ),
  );
}

class BukuKasApp extends StatelessWidget {
  final AppProvider appProvider;
  const BukuKasApp({super.key, required this.appProvider});

  @override
  Widget build(BuildContext context) {
    bool hasPin = appProvider.pinCode != null && appProvider.pinCode!.length == 6;

    return MaterialApp(
      title: 'Buku Kas Premium',
      theme: AppTheme.lightTheme,
      home: PinScreen(isCreateMode: !hasPin),
      debugShowCheckedModeBanner: false,
    );
  }
}
