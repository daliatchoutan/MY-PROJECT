import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NovaraApp());
}

class NovaraApp extends StatelessWidget {
  const NovaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) => MaterialApp(
          title: 'NOVARA',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D7A57),
              primary: const Color(0xFF0D7A57),
              secondary: const Color(0xFFE67E22),
              tertiary: const Color(0xFFF39C12),
              surface: Colors.grey.shade50,
            ),
            scaffoldBackgroundColor: const Color(0xFFF9FAF8),
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: false,
              backgroundColor: const Color(0xFF0D7A57),
              foregroundColor: Colors.white,
              titleTextStyle: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
