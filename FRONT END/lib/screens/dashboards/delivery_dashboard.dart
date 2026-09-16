import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/language_switcher.dart';
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
  int _unreadNotifsCount = 0;
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
      int unread = 0;
      try {
        final notifs = await auth.api.getNotifications();
        unread = notifs.where((n) => n['isRead'] == false || n['isRead'] == 0).length;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _deliveries = deliveries;
          _unreadNotifsCount = unread;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String deliveryId, String newStatus) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    try {
      await auth.api.updateDeliveryStatus(deliveryId, newStatus);
      _loadDeliveries();
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locale.isFrench
                ? 'Statut de livraison mis à jour : $newStatus'
                : 'Delivery marked as $newStatus',
          ),
          backgroundColor: Colors.purple.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _showReportDelayDialog(String deliveryId) {
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final reasonCtrl = TextEditingController(
      text: locale.isFrench ? 'Ralentissement important sur la route / Embouteillages' : 'Heavy traffic delay on highway',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Text(locale.isFrench ? 'Signaler un retard' : 'Report Delivery Delay'),
          ],
        ),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: locale.isFrench ? 'Motif du retard' : 'Reason for Delay',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(locale.isFrench ? 'Annuler' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await auth.api.reportDelayedDelivery(deliveryId, reasonCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              _loadDeliveries();
              scaffoldMessenger.hideCurrentSnackBar();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    locale.isFrench
                        ? 'Retard signalé au client et au fermier'
                        : 'Delay reported to customer & farmer',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
            child: Text(locale.isFrench ? 'Confirmer le retard' : 'Report Delay'),
          ),
        ],
      ),
    );
  }

  void _confirmSuccessfulDelivery(String deliveryId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await auth.api.confirmDelivery(deliveryId);
      if (!mounted) return;
      _loadDeliveries();
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            locale.isFrench
                ? 'Livraison confirmée avec succès ! Client notifié.'
                : 'Delivery successfully confirmed and completed! Customer notified.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final locale = Provider.of<LocaleProvider>(context);
    final avatarUrl = auth.user?['avatarUrl'];

    final assignedCount = _deliveries.where((d) => d['status'] == 'assigned').length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset('assets/images/novara_logo.jpg', width: 30, height: 30, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            Text(locale.tr('role_delivery')),
          ],
        ),
        backgroundColor: const Color(0xFF6B21A8),
        foregroundColor: Colors.white,
        actions: [
          const LanguageSwitcher(isLight: true),
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
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications),
                if (_unreadNotifsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$_unreadNotifsCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              _loadDeliveries();
            },
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
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _deliveries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delivery_dining, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        locale.isFrench ? 'Aucune tâche de livraison assignée.' : 'No delivery tasks assigned yet.',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDeliveries,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _deliveries.length + (assignedCount > 0 ? 1 : 0),
                    itemBuilder: (ctx, idx) {
                      if (assignedCount > 0 && idx == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            border: Border.all(color: Colors.amber.shade800, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.notification_important, color: Colors.amber.shade900, size: 30),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale.isFrench ? 'Nouvelle mission de livraison !' : 'New Delivery Assignment!',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      locale.isFrench
                                          ? 'Vous avez $assignedCount livraison(s) assignée(s). Cliquez sur "Accepter la livraison" ci-dessous.'
                                          : 'You have $assignedCount pending task(s). Tap "Accept Delivery" below to confirm route.',
                                      style: TextStyle(fontSize: 12, color: Colors.brown.shade900),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final delIdx = assignedCount > 0 ? idx - 1 : idx;
                      final del = _deliveries[delIdx];
                      final status = del['status'] ?? 'assigned';
                      final isDelayed = del['isDelayed'] ?? false;

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                            : status == 'assigned'
                                                ? Colors.amber.shade100
                                                : Colors.purple.shade100,
                                  ),
                                ],
                              ),
                              const Divider(),
                              Text('📍 Dropoff Address: ${del['dropoffAddress'] ?? 'N/A'}'),
                              const SizedBox(height: 4),
                              Text('👤 Customer: ${del['order']?['customer']?['name'] ?? 'Customer'} (${del['order']?['customer']?['phone'] ?? 'N/A'})'),
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
                                      label: Text(locale.isFrench ? 'Accepter la livraison' : 'Accept Delivery'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                    ),
                                  if (status == 'accepted' || status == 'assigned')
                                    ElevatedButton.icon(
                                      onPressed: () => _updateStatus(del['id'], 'picked_up'),
                                      icon: const Icon(Icons.local_shipping_outlined),
                                      label: Text(locale.isFrench ? 'Colis récupéré' : 'Mark Picked Up'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                                    ),
                                  if (status != 'delivered')
                                    ElevatedButton.icon(
                                      onPressed: () => _showReportDelayDialog(del['id']),
                                      icon: const Icon(Icons.warning_amber),
                                      label: Text(locale.isFrench ? 'Signaler retard' : 'Report Delay'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
                                    ),
                                  if (status != 'delivered')
                                    ElevatedButton.icon(
                                      onPressed: () => _confirmSuccessfulDelivery(del['id']),
                                      icon: const Icon(Icons.task_alt),
                                      label: Text(locale.isFrench ? 'Confirmer livraison effectuée' : 'Confirm Successful Delivery'),
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
