import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../notifications_screen.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final stats = await auth.api.getAdminStats();
      final users = await auth.api.getAllUsers();
      if (mounted) {
        setState(() {
          _stats = stats;
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator Dashboard'),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAdminData),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Platform Overview'),
            Tab(icon: Icon(Icons.people), text: 'User Governance'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Users', '${_stats['totalUsers'] ?? 0}', Icons.people, Colors.blue)),
              Expanded(child: _buildStatCard('Total Farms', '${_stats['totalFarms'] ?? 0}', Icons.agriculture, Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Active Devices', '${_stats['totalDevices'] ?? 0}', Icons.sensors, Colors.orange)),
              Expanded(child: _buildStatCard('Total Orders', '${_stats['totalOrders'] ?? 0}', Icons.shopping_basket, Colors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.amber.shade50,
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, size: 40, color: Colors.amber),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Platform Gross Revenue', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text(
                        '\$${_stats['totalRevenue'] ?? 0.0}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (ctx, idx) {
        final u = _users[idx];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(u['name'][0].toUpperCase())),
            title: Text(u['name'] ?? 'User'),
            subtitle: Text('${u['email']} | Role: ${u['role']}'),
            trailing: PopupMenuButton<String>(
              onSelected: (role) async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.api.updateUserRole(u['id'], role);
                _loadAdminData();
              },
              itemBuilder: (ctx) => ['Administrator', 'Farmer', 'Customer', 'Delivery Person']
                  .map((r) => PopupMenuItem(value: r, child: Text('Set as $r')))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
