import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/language_switcher.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'visitor_marketplace_screen.dart';
import 'dashboards/farmer_dashboard.dart';
import 'dashboards/customer_dashboard.dart';
import 'dashboards/delivery_dashboard.dart';
import 'dashboards/admin_dashboard.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _navigateToDashboard(BuildContext context, String role) {
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
    final auth = Provider.of<AuthProvider>(context);
    final locale = Provider.of<LocaleProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Realistic Novara Smart Farm background photo
          Positioned.fill(
            child: Image.asset(
              'assets/images/farm_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay for contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
          // Language Switcher Top Right
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: const LanguageSwitcher(isLight: true),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.05),
                // Natural Logo
                Hero(
                  tag: 'novara_logo',
                  child: Container(
                    width: 105,
                    height: 105,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 6)),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/novara_logo.jpg', fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'NOVARA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.5,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Text(
                    locale.tr('app_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                // Bottom card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -6))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Feature tiles with vibrant colors
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFeatureTile(Icons.sensors, const Color(0xFFF39C12), 'IoT Monitor'),
                          _buildFeatureTile(Icons.warning_amber_rounded, const Color(0xFFE74C3C), 'AI Alerts'),
                          _buildFeatureTile(Icons.shopping_basket, const Color(0xFF0D7A57), 'Marketplace'),
                          _buildFeatureTile(Icons.local_shipping, const Color(0xFF8E44AD), 'Delivery'),
                        ],
                      ),
                      const SizedBox(height: 22),
                      if (auth.isAuthenticated) ...[
                        ElevatedButton.icon(
                          onPressed: () => _navigateToDashboard(context, auth.role),
                          icon: const Icon(Icons.dashboard),
                          label: Text('${locale.tr('role_${auth.role.toLowerCase().replaceAll(' ', '_')}')} Dashboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D7A57),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const VisitorMarketplaceScreen()),
                          ),
                          icon: const Icon(Icons.storefront, color: Color(0xFF0D7A57)),
                          label: Text(
                            locale.tr('browse_visitor'),
                            style: const TextStyle(color: Color(0xFF0D7A57), fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFF0D7A57), width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D7A57),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(locale.tr('sign_in'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE67E22),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(locale.tr('create_account'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            locale.tr('default_customer_note'),
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }
}
