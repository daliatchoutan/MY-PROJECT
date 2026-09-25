import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/language_switcher.dart';
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
  List<dynamic> _farmManagers = [];
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
      final farmManagers = await auth.api.getFarmManagers();
      if (mounted) {
        setState(() {
          _stats = stats;
          _reports = reports;
          _users = users;
          _farmManagers = farmManagers;
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
                items: ['Administrator', 'Farm Manager', 'Farmer', 'Customer', 'Delivery Person']
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
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
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
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    await auth.api.setUserStatus(userId, status);
    if (!mounted) return;
    _loadAdminData();
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('User status updated to $status')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final locale = Provider.of<LocaleProvider>(context);
    final avatarUrl = auth.user?['avatarUrl'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset('assets/images/novara_logo.jpg', width: 30, height: 30, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            Text(locale.tr('role_admin')),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          const LanguageSwitcher(isLight: true),
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
            Tab(icon: Icon(Icons.manage_accounts), text: 'Farm Managers'),
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
                _buildFarmManagersTab(),
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

  Widget _buildFarmManagersTab() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pendingManagers = _farmManagers.where((m) => m['status'] == 'pending').toList();

    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Farm Managers Governance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pendingManagers.isNotEmpty ? Colors.amber.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: pendingManagers.isNotEmpty ? Colors.amber.shade700 : Colors.green.shade700,
                  ),
                ),
                child: Text(
                  '${pendingManagers.length} Pending Approval',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: pendingManagers.isNotEmpty ? Colors.amber.shade900 : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Administrators validate or deny Farm Manager accounts. Once validated, Farm Managers govern operational farmers and logistics couriers.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_farmManagers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No Farm Manager accounts registered yet.')),
            )
          else
            ..._farmManagers.map((m) {
              final status = m['status'] ?? 'pending';
              final isPending = status == 'pending';
              final isRejected = status == 'rejected';
              final isActive = status == 'active';

              Color statusColor = Colors.grey;
              if (isActive) statusColor = Colors.green;
              if (isPending) statusColor = Colors.amber.shade800;
              if (isRejected) statusColor = Colors.red;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isPending ? Colors.amber.shade300 : Colors.grey.shade200,
                    width: isPending ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: isPending ? Colors.amber.shade100 : Colors.blue.shade100,
                            radius: 22,
                            child: Icon(
                              Icons.manage_accounts,
                              color: isPending ? Colors.amber.shade900 : Colors.blue.shade800,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m['name'] ?? 'Farm Manager',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m['email'] ?? '',
                                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                                ),
                                if (m['phone'] != null && m['phone'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Phone: ${m['phone']}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                                if (m['cniNumber'] != null && m['cniNumber'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'CNI / ID: ${m['cniNumber']}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0D7A57)),
                                  ),
                                ],
                                if (m['farmManagerId'] != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Manager Code: ${m['farmManagerId']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      if (isRejected && m['rejectionReason'] != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Reason: ${m['rejectionReason']}',
                            style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                          ),
                        ),
                      ],
                      if (isPending) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _promptRejectManager(m['id'], m['name']),
                              icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                              label: const Text('Deny', style: TextStyle(color: Colors.red, fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await auth.api.approveFarmManager(m['id']);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Farm Manager ${m['name']} approved successfully!'),
                                        backgroundColor: const Color(0xFF0D7A57),
                                      ),
                                    );
                                    _loadAdminData();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error approving manager: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Validate & Approve', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D7A57),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _promptRejectManager(String managerId, String? managerName) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Decline Farm Manager: ${managerName ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide the reason for declining this Farm Manager application:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. CNI document unverified, criteria not met...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final reason = reasonCtrl.text.trim();
              Navigator.pop(ctx);
              try {
                await auth.api.rejectFarmManager(managerId, reason.isNotEmpty ? reason : 'Criteria not met');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Farm Manager application declined.'), backgroundColor: Colors.orange.shade800),
                  );
                  _loadAdminData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error declining manager: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Decline Application'),
          ),
        ],
      ),
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
