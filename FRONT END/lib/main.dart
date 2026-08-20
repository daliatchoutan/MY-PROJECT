import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartPoultryApp());
}

class SmartPoultryApp extends StatelessWidget {
  const SmartPoultryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Poultry Farm',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            primary: Colors.green.shade700,
            secondary: Colors.amber.shade700,
          ),
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: false,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
