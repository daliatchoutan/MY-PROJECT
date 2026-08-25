import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'welcome_screen.dart';
import 'dashboards/farmer_dashboard.dart';
import 'dashboards/customer_dashboard.dart';
import 'dashboards/delivery_dashboard.dart';
import 'dashboards/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.tryAutoLogin();

    if (!mounted) return;

    if (auth.isAuthenticated) {
      _navigateToDashboard(auth.role);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  void _navigateToDashboard(String role) {
    Widget targetScreen;
    switch (role) {
      case 'Farmer':
        targetScreen = const FarmerDashboard();
        break;
      case 'Customer':
        targetScreen = const CustomerDashboard();
        break;
      case 'Delivery Person':
        targetScreen = const DeliveryDashboard();
        break;
      case 'Administrator':
        targetScreen = const AdminDashboard();
        break;
      default:
        targetScreen = const CustomerDashboard();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade800,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.egg_alt_rounded,
                size: 80,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'NOVARA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smart Poultry Farm Automation & Marketplace',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
