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
      body: Stack(
        children: [
          // Farm background
          Positioned.fill(
            child: Image.asset(
              'assets/images/farm_bg_1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
          // Centered content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'novara_logo',
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 6)),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/novara_logo.jpg', fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'NOVARA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Smart Poultry Farm Automation & Marketplace',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
