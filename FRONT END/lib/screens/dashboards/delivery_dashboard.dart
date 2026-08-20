import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../notifications_screen.dart';
import '../auth/login_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delivery marked as $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Courier Dashboard'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
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
                MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                                    backgroundColor: status == 'delivered' ? Colors.green.shade100 : Colors.purple.shade100,
                                  ),
                                ],
                              ),
                              const Divider(),
                              Text('📍 Dropoff Address: ${del['dropoffAddress'] ?? 'N/A'}'),
                              const SizedBox(height: 4),
                              Text('👤 Customer Phone: ${del['order']?['customer']?['phone'] ?? 'N/A'}'),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (status == 'assigned')
                                    ElevatedButton.icon(
                                      onPressed: () => _updateStatus(del['id'], 'accepted'),
                                      icon: const Icon(Icons.check_circle_outline),
                                      label: const Text('Accept'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                    ),
                                  if (status == 'accepted')
                                    ElevatedButton.icon(
                                      onPressed: () => _updateStatus(del['id'], 'picked_up'),
                                      icon: const Icon(Icons.local_shipping_outlined),
                                      label: const Text('Mark Picked Up'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                    ),
                                  if (status == 'picked_up')
                                    ElevatedButton.icon(
                                      onPressed: () => _updateStatus(del['id'], 'delivered'),
                                      icon: const Icon(Icons.task_alt),
                                      label: const Text('Confirm Delivered'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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
