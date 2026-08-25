import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../notifications_screen.dart';
import '../profile_screen.dart';
import '../welcome_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _reports = {};
  List<dynamic> _users = [];
  List<dynamic> _farmers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final stats = await auth.api.getAdminStats();
      final reports = await auth.api.getReports();
      final users = await auth.api.getAllUsers();
      final farmers = await auth.api.getFarmers();
      if (mounted) {
        setState(() {
          _stats = stats;
          _reports = reports;
          _users = users;
          _farmers = farmers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'password123');
    final phoneCtrl = TextEditingController();
    String selectedRole = 'Farmer';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create User Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['Administrator', 'Farmer', 'Customer', 'Delivery Person']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => selectedRole = val!,
              ),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.api.createUser({
                'name': nameCtrl.text,
                'email': emailCtrl.text,
                'password': passCtrl.text,
                'role': selectedRole,
                'phone': phoneCtrl.text,
              });
              Navigator.pop(ctx);
              _loadAdminData();
            },
            child: const Text('Create User'),
          )
        ],
      ),
    );
  }

  void _showUpdateUserDialog(dynamic u) {
    final nameCtrl = TextEditingController(text: u['name']);
    final emailCtrl = TextEditingController(text: u['email']);
    final phoneCtrl = TextEditingController(text: u['phone'] ?? '');
    String selectedRole = u['role'] ?? 'Customer';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update ${u['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['Administrator', 'Farmer', 'Customer', 'Delivery Person']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => selectedRole = val!,
              ),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.api.updateUser(u['id'], {
                'name': nameCtrl.text,
                'email': emailCtrl.text,
                'role': selectedRole,
                'phone': phoneCtrl.text,
              });
              Navigator.pop(ctx);
              _loadAdminData();
            },
            child: const Text('Save Changes'),
          )
        ],
      ),
    );
  }

  void _setUserStatus(String userId, String status) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.api.setUserStatus(userId, status);
    _loadAdminData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User status updated to $status')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final avatarUrl = auth.user?['avatarUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVARA Administrator Portal'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              backgroundImage: (avatarUrl != null && avatarUrl.toString().isNotEmpty) ? NetworkImage(avatarUrl) : null,
              child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                  ? Text((auth.user?['name'] ?? 'A')[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.blueGrey))
                  : null,
            ),
            tooltip: 'My Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
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
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
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
            Tab(icon: Icon(Icons.analytics), text: 'Reports & Revenue'),
            Tab(icon: Icon(Icons.agriculture), text: 'Farmers Directory'),
            Tab(icon: Icon(Icons.people), text: 'User Governance'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportsTab(),
                _buildFarmersTab(),
                _buildUsersTab(),
              ],
            ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Users', '${_stats['totalUsers'] ?? 0}', Icons.people, Colors.blue)),
              Expanded(child: _buildStatCard('Farmers Registered', '${_stats['totalFarmers'] ?? 0}', Icons.agriculture, Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Active Devices', '${_stats['totalDevices'] ?? 0}', Icons.sensors, Colors.orange)),
              Expanded(child: _buildStatCard('Total Orders', '${_stats['totalOrders'] ?? 0}', Icons.shopping_basket, Colors.purple)),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.green.shade50,
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.green.shade700, radius: 24, child: const Icon(Icons.payments, color: Colors.white, size: 28)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Platform Financial Revenue', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(
                        '${_stats['totalRevenue'] ?? 0} FCFA',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Analytics Report Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.blue),
                  title: const Text('Total Sales Transactions'),
                  trailing: Text('${_reports['totalSales'] ?? 0} orders', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Confirmed Paid Orders'),
                  trailing: Text('${_reports['paidOrdersCount'] ?? 0} paid', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.local_shipping, color: Colors.purple),
                  title: const Text('Successfully Delivered Orders'),
                  trailing: Text('${_reports['deliveredOrdersCount'] ?? 0} delivered', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
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
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmersTab() {
    return _farmers.isEmpty
        ? const Center(child: Text('No farmers registered in directory.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _farmers.length,
            itemBuilder: (ctx, idx) {
              final f = _farmers[idx];
              final farmsCount = f['farms']?.length ?? 0;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: Icon(Icons.agriculture, color: Colors.green.shade800)),
                  title: Text(f['name'] ?? 'Farmer'),
                  subtitle: Text('${f['email']} | Phone: ${f['phone'] ?? 'N/A'}\nOperates $farmsCount farm(s)'),
                  isThreeLine: true,
                ),
              );
            },
          );
  }

  Widget _buildUsersTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        backgroundColor: Colors.blueGrey.shade800,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Create User', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (ctx, idx) {
          final u = _users[idx];
          final status = u['status'] ?? 'active';

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: status == 'blocked' ? Colors.red.shade100 : status == 'suspended' ? Colors.orange.shade100 : Colors.blue.shade100,
                      child: Text(u['name'][0].toUpperCase()),
                    ),
                    title: Text(u['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${u['email']} | Role: ${u['role']}\nStatus: ${status.toUpperCase()}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showUpdateUserDialog(u),
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (status != 'active')
                        TextButton.icon(
                          onPressed: () => _setUserStatus(u['id'], 'active'),
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          label: const Text('Activate', style: TextStyle(color: Colors.green)),
                        ),
                      if (status != 'suspended')
                        TextButton.icon(
                          onPressed: () => _setUserStatus(u['id'], 'suspended'),
                          icon: const Icon(Icons.pause_circle_outline, color: Colors.orange, size: 16),
                          label: const Text('Suspend', style: TextStyle(color: Colors.orange)),
                        ),
                      if (status != 'blocked')
                        TextButton.icon(
                          onPressed: () => _setUserStatus(u['id'], 'blocked'),
                          icon: const Icon(Icons.block, color: Colors.red, size: 16),
                          label: const Text('Block User', style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
