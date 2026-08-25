import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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

    // If authenticated, automatically show a button to enter dashboard
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade900,
              Colors.green.shade700,
              Colors.green.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Logo & App Name
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Icon(
                  Icons.egg_alt_rounded,
                  size: 72,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'NOVARA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Smart Poultry Farm Automation & Marketplace System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Feature Highlights Grid
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome to NOVARA',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Automating poultry farms, monitoring conditions, and connecting farmers with customers in FCFA.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 24),

                        // Features List
                        _buildFeatureTile(
                          icon: Icons.sensors,
                          color: Colors.orange,
                          title: 'IoT Condition Monitoring',
                          subtitle: 'Real-time telemetry for food, water, temperature & humidity.',
                        ),
                        _buildFeatureTile(
                          icon: Icons.warning_amber_rounded,
                          color: Colors.red,
                          title: 'AI Health Alert System',
                          subtitle: 'Computer vision early disease and anomaly detection.',
                        ),
                        _buildFeatureTile(
                          icon: Icons.shopping_basket,
                          color: Colors.green,
                          title: 'Marketplace in FCFA',
                          subtitle: 'Buy & sell farm-fresh eggs, live poultry & feed.',
                        ),
                        _buildFeatureTile(
                          icon: Icons.local_shipping,
                          color: Colors.purple,
                          title: 'Logistics & Order Tracking',
                          subtitle: 'Real-time courier delivery tracking and status updates.',
                        ),

                        const SizedBox(height: 24),

                        if (auth.isAuthenticated) ...[
                          ElevatedButton.icon(
                            onPressed: () => _navigateToDashboard(context, auth.role),
                            icon: const Icon(Icons.dashboard),
                            label: Text('Enter ${auth.role} Dashboard'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ] else ...[
                          // Visitor Browse Button
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const VisitorMarketplaceScreen()),
                              );
                            },
                            icon: const Icon(Icons.storefront, color: Colors.green),
                            label: const Text(
                              'Browse Marketplace as Visitor',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.green.shade700, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade800,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade800,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: 24,
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
