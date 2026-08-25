import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../notifications_screen.dart';
import '../profile_screen.dart';
import '../welcome_screen.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _farms = [];
  List<dynamic> _devices = [];
  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  List<dynamic> _notifications = [];
  Map<String, dynamic> _liveReadings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final farms = await auth.api.getFarms();
      final devices = await auth.api.getDevices();
      final products = await auth.api.getProducts();
      final orders = await auth.api.getOrders();
      final notifs = await auth.api.getNotifications();

      Map<String, dynamic> readings = {};
      for (var dev in devices) {
        final reading = await auth.api.getLiveReading(dev['id']);
        readings[dev['id']] = reading;
      }

      if (mounted) {
        setState(() {
          _farms = farms;
          _devices = devices;
          _products = products;
          _orders = orders;
          _notifications = notifs;
          _liveReadings = readings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddFarmDialog() {
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '1000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Poultry Farm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Farm Name')),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location / Region')),
            TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Poultry Capacity')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.api.createFarm({
                'name': nameCtrl.text,
                'location': locCtrl.text,
                'capacity': int.tryParse(capCtrl.text) ?? 1000,
              });
              Navigator.pop(ctx);
              _loadFarmerData();
            },
            child: const Text('Save Farm'),
          )
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    if (_farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a farm first')));
      return;
    }
    final serialCtrl = TextEditingController(text: 'ESP32-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final nameCtrl = TextEditingController(text: 'Coop #1 Main Sensor Cluster');
    String selectedFarmId = _farms.first['id'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register IoT Device Cluster'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedFarmId,
              items: _farms.map<DropdownMenuItem<String>>((f) => DropdownMenuItem(value: f['id'].toString(), child: Text(f['name']))).toList(),
              onChanged: (val) => selectedFarmId = val!,
              decoration: const InputDecoration(labelText: 'Select Farm'),
            ),
            TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: 'Device Serial Number')),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Cluster / Coop Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.api.registerDevice({
                'deviceSerial': serialCtrl.text,
                'name': nameCtrl.text,
                'farmId': selectedFarmId,
              });
              Navigator.pop(ctx);
              _loadFarmerData();
            },
            child: const Text('Register'),
          )
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    if (_farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a farm first')));
      return;
    }
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '5000');
    final stockCtrl = TextEditingController(text: '50');
    String selectedFarmId = _farms.first['id'];
    String category = 'Eggs';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product to Marketplace'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedFarmId,
                items: _farms.map<DropdownMenuItem<String>>((f) => DropdownMenuItem(value: f['id'].toString(), child: Text(f['name']))).toList(),
                onChanged: (val) => selectedFarmId = val!,
                decoration: const InputDecoration(labelText: 'Select Farm'),
              ),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (FCFA)')),
              TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stock Quantity')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.api.createProduct({
                'farmId': selectedFarmId,
                'name': nameCtrl.text,
                'description': descCtrl.text,
                'price': double.tryParse(priceCtrl.text) ?? 5000.0,
                'stockQuantity': int.tryParse(stockCtrl.text) ?? 50,
                'category': category,
              });
              Navigator.pop(ctx);
              _loadFarmerData();
            },
            child: const Text('Add Product'),
          )
        ],
      ),
    );
  }

  void _showSensorHistoryDialog(String deviceId, String deviceName) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final history = await auth.api.getSensorHistory(deviceId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sensor History: $deviceName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: history.isEmpty
              ? const Center(child: Text('No historical sensor telemetry recorded yet.'))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (ctx, idx) {
                    final item = history[idx];
                    return ListTile(
                      dense: true,
                      title: Text('Temp: ${item['temperature']}°C | Humidity: ${item['humidity']}%'),
                      subtitle: Text('Food: ${item['foodLevel']}% | Water: ${item['waterLevel']}%'),
                      trailing: Text(
                        item['createdAt'] != null ? item['createdAt'].toString().substring(11, 19) : '',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _toggleAutoMode(String deviceId, bool currentAutoMode) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await auth.api.toggleAutoMode(deviceId, !currentAutoMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? 'Mode updated')),
    );
    _loadFarmerData();
  }

  void _triggerManualOverride(String deviceId, String action) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await auth.api.manualOverride(deviceId, action);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? 'Override command executed'), backgroundColor: Colors.amber.shade900),
    );
  }

  void _simulateTelemetry(String deviceSerial) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await auth.api.sendTelemetry({
      'deviceSerial': deviceSerial,
      'foodLevel': 15.0, // Low -> triggers dispenser
      'waterLevel': 85.0,
      'temperature': 34.5, // High -> triggers fan
      'humidity': 60.0,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Telemetry sent! Triggers: ${res['automationTriggers']?.length ?? 0}')),
    );
    _loadFarmerData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final unreadNotifs = _notifications.where((n) => !(n['isRead'] ?? false)).length;
    final avatarUrl = auth.user?['avatarUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVARA Farmer Portal'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              backgroundImage: (avatarUrl != null && avatarUrl.toString().isNotEmpty) ? NetworkImage(avatarUrl) : null,
              child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                  ? Text((auth.user?['name'] ?? 'F')[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.green))
                  : null,
            ),
            tooltip: 'My Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ).then((_) => _loadFarmerData()),
              ),
              if (unreadNotifs > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '$unreadNotifs',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
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
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.agriculture), text: 'Farms'),
            Tab(icon: Icon(Icons.sensors), text: 'Conditions & IoT'),
            Tab(icon: Icon(Icons.warning_amber), text: 'AI Health Alerts'),
            Tab(icon: Icon(Icons.inventory), text: 'Products'),
            Tab(icon: Icon(Icons.shopping_basket), text: 'Customer Orders'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFarmsTab(),
                _buildIoTTab(),
                _buildAiAlertsTab(),
                _buildProductsTab(),
                _buildOrdersTab(),
              ],
            ),
    );
  }

  Widget _buildFarmsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFarmDialog,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _farms.isEmpty
          ? const Center(child: Text('No farms registered yet. Click + to add your poultry farm.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _farms.length,
              itemBuilder: (ctx, idx) {
                final f = _farms[idx];
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
                            Text(f['name'] ?? 'Farm', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Chip(label: Text('${f['devices']?.length ?? 0} IoT Clusters'), backgroundColor: Colors.green.shade50),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('📍 Location: ${f['location'] ?? 'N/A'}'),
                        Text('🐔 Flock Capacity: ${f['currentPoultryCount'] ?? 0} / ${f['capacity'] ?? 0} birds'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildIoTTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeviceDialog,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add_location_alt, color: Colors.white),
      ),
      body: _devices.isEmpty
          ? const Center(child: Text('No IoT devices registered.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _devices.length,
              itemBuilder: (ctx, idx) {
                final d = _devices[idx];
                final reading = _liveReadings[d['id']] ?? {};

                final food = reading['foodLevel'] ?? 50.0;
                final water = reading['waterLevel'] ?? 75.0;
                final temp = reading['temperature'] ?? 24.5;
                final humidity = reading['humidity'] ?? 65.0;
                final isAuto = d['autoMode'] ?? true;
                final healthStatus = d['healthStatus'] ?? 'good';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['name'] ?? 'Device Cluster', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(d['deviceSerial'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            Chip(
                              label: Text('Health: ${healthStatus.toUpperCase()}'),
                              backgroundColor: healthStatus == 'good' ? Colors.green.shade100 : Colors.orange.shade100,
                            ),
                          ],
                        ),
                        const Divider(),
                        // Auto vs Manual Toggle Switch
                        Container(
                          color: isAuto ? Colors.green.shade50 : Colors.amber.shade50,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isAuto ? '🤖 AUTOMATIC THRESHOLD CONTROL' : '⚙️ MANUAL OVERRIDE CONTROL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isAuto ? Colors.green.shade900 : Colors.amber.shade900,
                                ),
                              ),
                              Switch(
                                value: isAuto,
                                activeColor: Colors.green,
                                onChanged: (val) => _toggleAutoMode(d['id'], isAuto),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildGaugeCard('Water Level', '${water.toStringAsFixed(1)}%', Icons.water_drop, water < (d['waterThreshold'] ?? 20) ? Colors.red : Colors.blue)),
                            Expanded(child: _buildGaugeCard('Temperature', '${temp.toStringAsFixed(1)}°C', Icons.thermostat, Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildGaugeCard('Food Level', '${food.toStringAsFixed(1)}%', Icons.restaurant, food < (d['foodThreshold'] ?? 20) ? Colors.red : Colors.green)),
                            Expanded(child: _buildGaugeCard('Humidity', '${humidity.toStringAsFixed(1)}%', Icons.water, Colors.teal)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showSensorHistoryDialog(d['id'], d['name']),
                              icon: const Icon(Icons.history),
                              label: const Text('Review Sensor Log'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _simulateTelemetry(d['deviceSerial']),
                              icon: const Icon(Icons.sensors),
                              label: const Text('Simulate Telemetry'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
                            ),
                          ],
                        ),
                        if (!isAuto) ...[
                          const Divider(),
                          const Text('Manual Actuator Controls:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: () => _triggerManualOverride(d['id'], 'FEEDER_ON'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                                child: const Text('Trigger Feeder'),
                              ),
                              ElevatedButton(
                                onPressed: () => _triggerManualOverride(d['id'], 'WATER_VALVE_ON'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, foregroundColor: Colors.white),
                                child: const Text('Open Water Valve'),
                              ),
                              ElevatedButton(
                                onPressed: () => _triggerManualOverride(d['id'], 'FAN_ON'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800, foregroundColor: Colors.white),
                                child: const Text('Activate Cooling Fan'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildGaugeCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAlertsTab() {
    final aiNotifs = _notifications.where((n) => n['type'] == 'ai_alert').toList();
    return aiNotifs.isEmpty
        ? const Center(child: Text('No AI health anomaly warnings reported.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: aiNotifs.length,
            itemBuilder: (ctx, idx) {
              final item = aiNotifs[idx];
              return Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.warning, color: Colors.white)),
                  title: Text(item['title'] ?? 'AI Health Alert', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['message'] ?? ''),
                ),
              );
            },
          );
  }

  Widget _buildProductsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
      body: _products.isEmpty
          ? const Center(child: Text('No inventory products listed.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (ctx, idx) {
                final p = _products[idx];
                return Card(
                  child: ListTile(
                    title: Text(p['name'] ?? 'Product'),
                    subtitle: Text('${p['price']} FCFA | Stock: ${p['stockQuantity']} ${p['unit']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        await auth.api.deleteProduct(p['id']);
                        _loadFarmerData();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOrdersTab() {
    return _orders.isEmpty
        ? const Center(child: Text('No customer orders received yet.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _orders.length,
            itemBuilder: (ctx, idx) {
              final o = _orders[idx];
              return Card(
                child: ListTile(
                  title: Text('Order #${o['id'].toString().substring(0, 8)}'),
                  subtitle: Text('Total: ${o['totalAmount']} FCFA | Payment: ${o['paymentStatus']} | Status: ${o['status']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (status) async {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      await auth.api.updateOrderStatus(o['id'], status);
                      _loadFarmerData();
                    },
                    itemBuilder: (ctx) => ['accepted', 'rejected', 'in_transit', 'delivered']
                        .map((s) => PopupMenuItem(value: s, child: Text(s)))
                        .toList(),
                  ),
                ),
              );
            },
          );
  }
}
