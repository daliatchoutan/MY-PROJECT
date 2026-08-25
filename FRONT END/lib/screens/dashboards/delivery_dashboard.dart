import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../notifications_screen.dart';
import '../profile_screen.dart';
import '../welcome_screen.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  List<dynamic> _deliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final deliveries = await auth.api.getDeliveries();
      if (mounted) {
        setState(() {
          _deliveries = deliveries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String deliveryId, String newStatus) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.api.updateDeliveryStatus(deliveryId, newStatus);
      _loadDeliveries();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delivery marked as $newStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _showReportDelayDialog(String deliveryId) {
    final reasonCtrl = TextEditingController(text: 'Heavy traffic delay on highway');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Delivery Delay'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Reason for Delay',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.api.reportDelayedDelivery(deliveryId, reasonCtrl.text);
              Navigator.pop(ctx);
              _loadDeliveries();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delay reported to customer & farmer'), backgroundColor: Colors.orange),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
            child: const Text('Report Delay'),
          ),
        ],
      ),
    );
  }

  void _confirmSuccessfulDelivery(String deliveryId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.api.confirmDelivery(deliveryId);
      _loadDeliveries();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery successfully confirmed and completed!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final avatarUrl = auth.user?['avatarUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVARA Courier Portal'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              backgroundImage: (avatarUrl != null && avatarUrl.toString().isNotEmpty) ? NetworkImage(avatarUrl) : null,
              child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                  ? Text((auth.user?['name'] ?? 'D')[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.purple))
                  : null,
            ),
            tooltip: 'My Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveries,
          ),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deliveries.isEmpty
              ? const Center(child: Text('No delivery tasks assigned.'))
              : RefreshIndicator(
                  onRefresh: _loadDeliveries,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _deliveries.length,
                    itemBuilder: (ctx, idx) {
                      final del = _deliveries[idx];
                      final status = del['status'] ?? 'assigned';
                      final isDelayed = del['isDelayed'] ?? false;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Delivery #${del['id'].toString().substring(0, 8)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Chip(
                                    label: Text(status.toUpperCase()),
                                    backgroundColor: status == 'delivered'
                                        ? Colors.green.shade100
                                        : status == 'delayed'
                                            ? Colors.orange.shade100
                                            : Colors.purple.shade100,
                                  ),
                                ],
                              ),
                              const Divider(),
                              Text('📍 Dropoff Address: ${del['dropoffAddress'] ?? 'N/A'}'),
                              const SizedBox(height: 4),
                              Text('👤 Customer Contact: ${del['order']?['customer']?['name'] ?? 'Customer'} (${del['order']?['customer']?['phone'] ?? 'N/A'})'),
                              if (isDelayed) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.orange.shade50,
                                  child: Text('⚠️ Delay Reason: ${del['delayReason'] ?? 'Delayed'}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (status == 'assigned')
                                    ElevatedButton.icon(
                                      onPressed: () => _updateStatus(del['id'], 'accepted'),
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: const Text('Accept Delivery'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                    ),
                                  if (status == 'accepted' || status == 'assigned')
                                    ElevatedButton.icon(
                                      onPressed: () => _updateStatus(del['id'], 'picked_up'),
                                      icon: const Icon(Icons.local_shipping_outlined),
                                      label: const Text('Mark Picked Up'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                                    ),
                                  if (status != 'delivered')
                                    ElevatedButton.icon(
                                      onPressed: () => _showReportDelayDialog(del['id']),
                                      icon: const Icon(Icons.warning_amber),
                                      label: const Text('Report Delay'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                                    ),
                                  if (status != 'delivered')
                                    ElevatedButton.icon(
                                      onPressed: () => _confirmSuccessfulDelivery(del['id']),
                                      icon: const Icon(Icons.task_alt),
                                      label: const Text('Confirm Successful Delivery'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
