import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/language_switcher.dart';
import '../../utils/product_helper.dart';
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
  List<dynamic> _managedFarmers = [];
  List<dynamic> _managedCouriers = [];
  List<dynamic> _pendingFarmers = [];
  List<dynamic> _pendingCouriers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isManager = auth.role == 'Farm Manager';
    _tabController = TabController(length: isManager ? 7 : 5, vsync: this);
    _loadFarmerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

      List<dynamic> managedFarmers = [];
      List<dynamic> managedCouriers = [];
      List<dynamic> pendingFarmers = [];
      List<dynamic> pendingCouriers = [];

      if (auth.role == 'Farm Manager') {
        try {
          final pending = await auth.api.getPendingApprovals();
          managedFarmers = await auth.api.getFarmers();
          managedCouriers = await auth.api.getDeliveryPersons();
          pendingFarmers = (pending['pendingFarmers'] as List<dynamic>?) ?? [];
          pendingCouriers = (pending['pendingDrivers'] as List<dynamic>?) ?? [];
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _farms = farms;
          _devices = devices;
          _products = products;
          _orders = orders;
          _notifications = notifs;
          _liveReadings = readings;
          _managedFarmers = managedFarmers;
          _managedCouriers = managedCouriers;
          _pendingFarmers = pendingFarmers;
          _pendingCouriers = pendingCouriers;
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
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Poultry Farm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Farm Name *',
                  hintText: 'e.g. Green Valley Farm',
                ),
              ),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location / Region *',
                  hintText: 'e.g. Yaounde, Obala',
                ),
              ),
              TextField(
                controller: capCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Poultry Capacity'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final location = locCtrl.text.trim();
                      if (name.isEmpty || location.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Farm Name and Location are required.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      try {
                        await auth.api.createFarm({
                          'name': name,
                          'location': location,
                          'capacity': int.tryParse(capCtrl.text) ?? 1000,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Farm created successfully!'),
                            backgroundColor: Color(0xFF0D7A57),
                          ),
                        );
                        if (!mounted) return;
                        _loadFarmerData();
                      } catch (err) {
                        setDialogState(() => isSaving = false);
                        final errMsg = err.toString().replaceAll('Exception: ', '');
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(errMsg),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Farm'),
            )
          ],
        ),
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
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              _loadFarmerData();
            },
            child: const Text('Register'),
          )
        ],
      ),
    );
  }

  final List<Map<String, String>> _backendCatalogPresets = [
    {
      'name': 'Broiler Chicken',
      'category': 'Live Poultry',
      'url': '/uploads/products/product_broiler.jpg',
      'asset': 'assets/images/product_broiler.jpg',
      'unit': 'bird',
    },
    {
      'name': 'Layer Chicken',
      'category': 'Live Poultry',
      'url': '/uploads/products/product_layer.jpg',
      'asset': 'assets/images/product_layer.jpg',
      'unit': 'bird',
    },
    {
      'name': 'Day-Old Chicks',
      'category': 'Live Poultry',
      'url': '/uploads/products/product_chicks.jpg',
      'asset': 'assets/images/product_chicks.jpg',
      'unit': 'chick',
    },
    {
      'name': 'Mature Rooster',
      'category': 'Live Poultry',
      'url': '/uploads/products/product_rooster.jpg',
      'asset': 'assets/images/product_rooster.jpg',
      'unit': 'bird',
    },
    {
      'name': 'Farm-Fresh Whole Chicken',
      'category': 'Poultry Meat',
      'url': '/uploads/products/product_fresh_chicken.jpg',
      'asset': 'assets/images/product_fresh_chicken.jpg',
      'unit': 'kg',
    },
    {
      'name': 'Organic Brown Eggs Tray (30 Eggs)',
      'category': 'Eggs',
      'url': '/uploads/products/product_brown_eggs.jpg',
      'asset': 'assets/images/product_brown_eggs.jpg',
      'unit': 'tray',
    },
    {
      'name': 'Fresh Farm Eggs Basket',
      'category': 'Eggs',
      'url': '/uploads/products/product_eggs.jpg',
      'asset': 'assets/images/product_eggs.jpg',
      'unit': 'crate',
    },
    {
      'name': 'Poultry Cuts & Fillets',
      'category': 'Poultry Meat',
      'url': '/uploads/products/product_meat.jpg',
      'asset': 'assets/images/product_meat.jpg',
      'unit': 'kg',
    },
    {
      'name': 'Nutritional Poultry Feed',
      'category': 'Poultry Feed',
      'url': '/uploads/products/product_feed.jpg',
      'asset': 'assets/images/product_feed.jpg',
      'unit': '50kg bag',
    },
  ];

  void _showAddProductDialog() {
    if (_farms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Create a farm first')));
      return;
    }
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final nameCtrl = TextEditingController(text: 'Broiler Chicken');
    final descCtrl = TextEditingController(text: 'Healthy, organically fed farm poultry');
    final priceCtrl = TextEditingController(text: '4500');
    final stockCtrl = TextEditingController(text: '50');
    String selectedFarmId = _farms.first['id'].toString();
    String category = 'Live Poultry';
    String unit = 'bird';
    Uint8List? pickedImageBytes;
    String? pickedImageBase64;
    String? selectedPresetUrl = '/uploads/products/product_broiler.jpg';
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(locale.isFrench ? 'Ajouter un Produit (Hébergé au Backend)' : 'Add Product to Marketplace'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedFarmId,
                    items: _farms.map<DropdownMenuItem<String>>((f) => DropdownMenuItem(value: f['id'].toString(), child: Text(f['name']))).toList(),
                    onChanged: (val) => setDialogState(() => selectedFarmId = val!),
                    decoration: InputDecoration(labelText: locale.isFrench ? 'Ferme' : 'Select Farm'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: ['Live Poultry', 'Eggs', 'Poultry Meat', 'Poultry Feed']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        category = val!;
                        if (category == 'Live Poultry') {
                          unit = 'bird';
                          selectedPresetUrl = '/uploads/products/product_broiler.jpg';
                        } else if (category == 'Eggs') {
                          unit = 'tray';
                          selectedPresetUrl = '/uploads/products/product_eggs.jpg';
                        } else if (category == 'Poultry Meat') {
                          unit = 'kg';
                          selectedPresetUrl = '/uploads/products/product_fresh_chicken.jpg';
                        } else if (category == 'Poultry Feed') {
                          unit = '50kg bag';
                          selectedPresetUrl = '/uploads/products/product_feed.jpg';
                        }
                      });
                    },
                    decoration: InputDecoration(labelText: locale.isFrench ? 'Catégorie' : 'Category'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: locale.isFrench ? 'Nom du Produit' : 'Product Name',
                      hintText: 'e.g. Broiler Chicken / Poulet de chair',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: locale.isFrench ? 'Prix (FCFA)' : 'Price (FCFA)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: locale.isFrench ? 'Stock' : 'Stock Qty'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: unit,
                          items: ['bird', 'tray', 'kg', '50kg bag', 'unit', 'crate']
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (val) => setDialogState(() => unit = val!),
                          decoration: InputDecoration(labelText: locale.isFrench ? 'Unité' : 'Unit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(labelText: locale.isFrench ? 'Description' : 'Description'),
                  ),
                  const SizedBox(height: 16),
                  // Image upload section
                  Text(
                    locale.isFrench ? 'Photo du Produit (Hébergée au Backend)' : 'Product Image (Backend Upload / Hosting)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: pickedImageBytes != null
                                ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                                : ProductHelper.buildProductImage(
                                    {'imageUrl': selectedPresetUrl, 'category': category, 'name': nameCtrl.text},
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pickedImageBytes != null
                                    ? (locale.isFrench ? 'Photo personnalisée prête à téléverser' : 'Custom photo ready to upload')
                                    : (locale.isFrench ? 'Image sélectionnée du catalogue backend' : 'Backend catalog image selected'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: isUploading
                                        ? null
                                        : () async {
                                            try {
                                              final picker = ImagePicker();
                                              final picked = await picker.pickImage(
                                                source: ImageSource.gallery,
                                                maxWidth: 800,
                                                maxHeight: 800,
                                                imageQuality: 80,
                                              );
                                              if (picked != null) {
                                                final bytes = await picked.readAsBytes();
                                                final base64 = base64Encode(bytes);
                                                setDialogState(() {
                                                  pickedImageBytes = bytes;
                                                  pickedImageBase64 = base64;
                                                });
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(locale.isFrench ? 'Erreur galerie: $e' : 'Gallery error: $e')),
                                                );
                                              }
                                            }
                                          },
                                    icon: const Icon(Icons.upload_file, size: 14),
                                    label: Text(locale.isFrench ? 'Téléverser' : 'Upload', style: const TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D7A57),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    onPressed: isUploading
                                        ? null
                                        : () async {
                                            try {
                                              final picker = ImagePicker();
                                              final picked = await picker.pickImage(
                                                source: ImageSource.camera,
                                                maxWidth: 800,
                                                maxHeight: 800,
                                                imageQuality: 80,
                                              );
                                              if (picked != null) {
                                                final bytes = await picked.readAsBytes();
                                                final base64 = base64Encode(bytes);
                                                setDialogState(() {
                                                  pickedImageBytes = bytes;
                                                  pickedImageBase64 = base64;
                                                });
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(locale.isFrench ? 'Erreur caméra: $e' : 'Camera error: $e')),
                                                );
                                              }
                                            }
                                          },
                                    icon: const Icon(Icons.camera_alt, size: 14),
                                    label: Text(locale.isFrench ? 'Caméra' : 'Camera', style: const TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locale.isFrench ? 'Ou choisir une image pré-hébergée au backend:' : 'Or choose a pre-hosted backend image:',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 58,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _backendCatalogPresets.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 6),
                      itemBuilder: (ctx, idx) {
                        final preset = _backendCatalogPresets[idx];
                        final isSelected = pickedImageBytes == null && selectedPresetUrl == preset['url'];

                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedPresetUrl = preset['url'];
                              pickedImageBytes = null;
                              pickedImageBase64 = null;
                              if (nameCtrl.text.isEmpty || nameCtrl.text == 'Broiler Chicken') {
                                nameCtrl.text = preset['name']!;
                                category = preset['category']!;
                                unit = preset['unit']!;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0D7A57) : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(preset['asset']!, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(locale.isFrench ? 'Annuler' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(locale.isFrench ? 'Veuillez saisir un nom' : 'Please enter a product name')),
                        );
                        return;
                      }

                      setDialogState(() => isUploading = true);
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final payload = <String, dynamic>{
                          'farmId': selectedFarmId,
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'price': double.tryParse(priceCtrl.text) ?? 5000.0,
                          'stockQuantity': int.tryParse(stockCtrl.text) ?? 50,
                          'category': category,
                          'unit': unit,
                        };

                        if (pickedImageBase64 != null) {
                          payload['imageBase64'] = pickedImageBase64;
                        } else if (selectedPresetUrl != null) {
                          payload['imageUrl'] = selectedPresetUrl;
                        }

                        await auth.api.createProduct(payload);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        _loadFarmerData();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(locale.isFrench ? 'Produit créé avec succès au backend !' : 'Product successfully created and image hosted on backend!'),
                            backgroundColor: const Color(0xFF0D7A57),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isUploading = false);
                        if (ctx.mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D7A57), foregroundColor: Colors.white),
              child: isUploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(locale.isFrench ? 'Enregistrer' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(dynamic product) {
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final nameCtrl = TextEditingController(text: product['name'] ?? '');
    final descCtrl = TextEditingController(text: product['description'] ?? '');
    final priceCtrl = TextEditingController(text: product['price']?.toString() ?? '5000');
    final stockCtrl = TextEditingController(text: product['stockQuantity']?.toString() ?? '50');
    String category = product['category'] ?? 'Live Poultry';
    String unit = product['unit'] ?? 'bird';
    Uint8List? pickedImageBytes;
    String? pickedImageBase64;
    String? selectedPresetUrl = product['imageUrl'];
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(locale.isFrench ? 'Modifier le Produit' : 'Edit Product'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: ['Live Poultry', 'Eggs', 'Poultry Meat', 'Poultry Feed']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => category = val!),
                    decoration: InputDecoration(labelText: locale.isFrench ? 'Catégorie' : 'Category'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(labelText: locale.isFrench ? 'Nom du Produit' : 'Product Name'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: locale.isFrench ? 'Prix (FCFA)' : 'Price (FCFA)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: locale.isFrench ? 'Stock' : 'Stock Qty'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: ['bird', 'tray', 'kg', '50kg bag', 'unit', 'crate'].contains(unit) ? unit : 'unit',
                          items: ['bird', 'tray', 'kg', '50kg bag', 'unit', 'crate']
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (val) => setDialogState(() => unit = val!),
                          decoration: InputDecoration(labelText: locale.isFrench ? 'Unité' : 'Unit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(labelText: locale.isFrench ? 'Description' : 'Description'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    locale.isFrench ? 'Photo du Produit' : 'Product Image',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: pickedImageBytes != null
                                ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                                : ProductHelper.buildProductImage(
                                    {'imageUrl': selectedPresetUrl, 'category': category, 'name': nameCtrl.text},
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pickedImageBytes != null
                                    ? (locale.isFrench ? 'Nouvelle photo sélectionnée' : 'New custom photo selected')
                                    : (locale.isFrench ? 'Photo actuelle hébergée au backend' : 'Current backend image'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final picker = ImagePicker();
                                        final picked = await picker.pickImage(
                                          source: ImageSource.gallery,
                                          maxWidth: 800,
                                          maxHeight: 800,
                                          imageQuality: 80,
                                        );
                                        if (picked != null) {
                                          final bytes = await picked.readAsBytes();
                                          final base64 = base64Encode(bytes);
                                          setDialogState(() {
                                            pickedImageBytes = bytes;
                                            pickedImageBase64 = base64;
                                          });
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(locale.isFrench ? 'Erreur galerie: $e' : 'Gallery error: $e')),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.photo_library, size: 14),
                                    label: Text(locale.isFrench ? 'Galerie' : 'Gallery', style: const TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D7A57),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final picker = ImagePicker();
                                        final picked = await picker.pickImage(
                                          source: ImageSource.camera,
                                          maxWidth: 800,
                                          maxHeight: 800,
                                          imageQuality: 80,
                                        );
                                        if (picked != null) {
                                          final bytes = await picked.readAsBytes();
                                          final base64 = base64Encode(bytes);
                                          setDialogState(() {
                                            pickedImageBytes = bytes;
                                            pickedImageBase64 = base64;
                                          });
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(locale.isFrench ? 'Erreur caméra: $e' : 'Camera error: $e')),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.camera_alt, size: 14),
                                    label: Text(locale.isFrench ? 'Caméra' : 'Camera', style: const TextStyle(fontSize: 11)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locale.isFrench ? 'Ou choisir une image prédéfinie:' : 'Or choose a catalog preset:',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 58,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _backendCatalogPresets.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 6),
                      itemBuilder: (ctx, idx) {
                        final preset = _backendCatalogPresets[idx];
                        final isSelected = pickedImageBytes == null && selectedPresetUrl == preset['url'];

                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedPresetUrl = preset['url'];
                              pickedImageBytes = null;
                              pickedImageBase64 = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0D7A57) : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(preset['asset']!, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(locale.isFrench ? 'Annuler' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final payload = <String, dynamic>{
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'price': double.tryParse(priceCtrl.text) ?? 5000.0,
                          'stockQuantity': int.tryParse(stockCtrl.text) ?? 50,
                          'category': category,
                          'unit': unit,
                        };

                        if (pickedImageBase64 != null) {
                          payload['imageBase64'] = pickedImageBase64;
                        } else if (selectedPresetUrl != null) {
                          payload['imageUrl'] = selectedPresetUrl;
                        }

                        await auth.api.updateProduct(product['id'], payload);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        _loadFarmerData();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(locale.isFrench ? 'Produit mis à jour avec succès !' : 'Product successfully updated on backend!'),
                            backgroundColor: const Color(0xFF0D7A57),
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (ctx.mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D7A57), foregroundColor: Colors.white),
              child: isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(locale.isFrench ? 'Mettre à jour' : 'Save Changes'),
            ),
          ],
        ),
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final res = await auth.api.toggleAutoMode(deviceId, !currentAutoMode);
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Mode updated'), backgroundColor: const Color(0xFF0D7A57)),
      );
      _loadFarmerData();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error toggling mode: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _triggerManualOverride(String deviceId, String action) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final res = await auth.api.manualOverride(deviceId, action);
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Override command executed'), backgroundColor: Colors.amber.shade900),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error executing command: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _simulateTelemetry(String deviceSerial) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final res = await auth.api.sendTelemetry({
        'deviceSerial': deviceSerial,
        'foodLevel': 15.0, // Low -> triggers dispenser
        'waterLevel': 85.0,
        'temperature': 34.5, // High -> triggers fan
        'humidity': 60.0,
      });
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Telemetry sent! Triggers: ${res['automationTriggers']?.length ?? 0}'),
          backgroundColor: const Color(0xFF0D7A57),
        ),
      );
      _loadFarmerData();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error simulating telemetry: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAlertDetailsDialog(dynamic item) {
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item['title'] ?? (locale.isFrench ? 'Alerte Sanitaire' : 'Health Alert'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['message'] ?? '', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            if (item['createdAt'] != null)
              Text(
                '${locale.isFrench ? 'Date' : 'Time'}: ${item['createdAt'].toString().replaceFirst('T', ' ').substring(0, 19)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale.isFrench ? 'Fermer' : 'Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                if (item['id'] != null) {
                  await auth.api.markNotificationAsRead(item['id'].toString());
                }
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
              _loadFarmerData();
            },
            icon: const Icon(Icons.check, size: 16),
            label: Text(locale.isFrench ? 'Marquer comme lu' : 'Acknowledge'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D7A57),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOrderStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.blue.shade700;
      case 'in_transit':
        return Colors.orange.shade800;
      case 'delivered':
        return const Color(0xFF0D7A57);
      case 'rejected':
      case 'cancelled':
        return Colors.red.shade700;
      case 'pending':
      default:
        return Colors.amber.shade800;
    }
  }

  void _showOrderDetailsDialog(dynamic o) {
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final items = (o['items'] as List<dynamic>?) ?? [];
    final delivery = o['delivery'];
    final driverName = delivery?['deliveryPerson']?['name'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF0D7A57)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Order #${o['id'].toString().substring(0, 8)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${o['customer']?['name'] ?? 'Customer'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (o['customer']?['phone'] != null)
                  Text('Phone: ${o['customer']?['phone']}', style: const TextStyle(color: Colors.grey)),
                if (o['shippingAddress'] != null)
                  Text('Shipping Address: ${o['shippingAddress']}', style: const TextStyle(color: Colors.grey)),
                const Divider(),
                const Text('Items Ordered:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                if (items.isEmpty)
                  const Text('No item details available.', style: TextStyle(fontStyle: FontStyle.italic))
                else
                  ...items.map((it) {
                    final pName = it['product']?['name'] ?? 'Product';
                    final qty = it['quantity'] ?? 1;
                    final price = it['unitPrice'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$qty x $pName'),
                          Text('${price * qty} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${o['totalAmount']} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D7A57))),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Payment: ${o['paymentStatus']?.toString().toUpperCase()} | Status: ${o['status']?.toString().toUpperCase()}'),
                if (driverName != null)
                  Text('Courier: $driverName (${delivery?['status'] ?? 'unassigned'})', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note, size: 20, color: Color(0xFF0D7A57)),
                      const SizedBox(width: 8),
                      Text(
                        locale.isFrench ? 'Modifier le statut :' : 'Change Status:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      DropdownButton<String>(
                        value: [
                          'pending',
                          'accepted',
                          'rejected',
                          'in_transit',
                          'delivered',
                          'cancelled'
                        ].contains(o['status']?.toString().toLowerCase())
                            ? o['status'].toString().toLowerCase()
                            : 'pending',
                        underline: const SizedBox(),
                        items: [
                          'pending',
                          'accepted',
                          'rejected',
                          'in_transit',
                          'delivered',
                          'cancelled'
                        ].map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getOrderStatusColor(s),
                                ),
                              ),
                            )).toList(),
                        onChanged: (newStatus) async {
                          if (newStatus == null) return;
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final scaffold = ScaffoldMessenger.of(context);
                          try {
                            await auth.api.updateOrderStatus(o['id'].toString(), newStatus);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!mounted) return;
                            _loadFarmerData();
                            scaffold.showSnackBar(
                              SnackBar(
                                content: Text('Order #${o['id'].toString().substring(0, 8)} status updated to ${newStatus.toUpperCase()}'),
                                backgroundColor: const Color(0xFF0D7A57),
                              ),
                            );
                          } catch (e) {
                            scaffold.showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showAssignDeliveryDialog(delivery?['id']?.toString() ?? o['id'].toString());
            },
            icon: const Icon(Icons.delivery_dining, size: 16),
            label: Text(driverName == null ? (locale.isFrench ? 'Assigner livreur' : 'Assign Courier') : (locale.isFrench ? 'Réassigner' : 'Reassign Courier')),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(dynamic p) {
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.isFrench ? 'Supprimer le produit' : 'Delete Product'),
        content: Text(
          locale.isFrench
              ? 'Voulez-vous vraiment supprimer "${p['name']}" ?'
              : 'Are you sure you want to delete "${p['name']}" from your inventory?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(locale.isFrench ? 'Annuler' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await auth.api.deleteProduct(p['id']);
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                _loadFarmerData();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(locale.isFrench ? 'Produit supprimé' : 'Product deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(locale.isFrench ? 'Supprimer' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showFarmDetailsDialog(dynamic f) {
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final devCount = f['devices']?.length ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.agriculture, color: Color(0xFF0D7A57)),
            const SizedBox(width: 8),
            Expanded(child: Text(f['name'] ?? 'Farm', style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 Location: ${f['location'] ?? 'N/A'}'),
            const SizedBox(height: 6),
            Text('🐔 Poultry Capacity: ${f['currentPoultryCount'] ?? 0} / ${f['capacity'] ?? 0} birds'),
            const SizedBox(height: 6),
            Text('📡 Connected IoT Clusters: $devCount'),
            if (f['status'] != null) ...[
              const SizedBox(height: 6),
              Text('Status: ${f['status'].toString().toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: f['status'] == 'approved' ? Colors.green : Colors.orange,
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditFarmDialog(f);
            },
            icon: const Icon(Icons.edit, size: 16),
            label: Text(locale.tr('edit_farm')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _tabController.animateTo(1); // Switch to IoT tab
            },
            icon: const Icon(Icons.sensors, size: 16),
            label: const Text('View IoT'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D7A57), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final locale = Provider.of<LocaleProvider>(context);
    final unreadNotifs = _notifications.where((n) => !(n['isRead'] ?? false)).length;
    final avatarUrl = auth.user?['avatarUrl'];

    final isManager = auth.role == 'Farm Manager';
    final roleTitle = isManager
        ? (locale.isFrench ? 'Chef d\'exploitation' : 'Farm Manager')
        : locale.tr('role_farmer');
    final displayId = isManager
        ? (auth.user?['farmManagerId'] ?? auth.user?['farmerId'])
        : auth.user?['farmerId'];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.asset('assets/images/novara_logo.jpg', width: 28, height: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                roleTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (displayId != null && displayId.toString().isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white54),
                ),
                child: Text(
                  displayId.toString(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ],
        ),
        actions: [
          const LanguageSwitcher(isLight: true),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              backgroundImage: (avatarUrl != null && avatarUrl.toString().isNotEmpty) ? NetworkImage(avatarUrl) : null,
              child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                  ? Text((auth.user?['name'] ?? 'F')[0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFF0D7A57)))
                  : null,
            ),
            tooltip: 'My Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            tooltip: locale.isFrench ? 'Alertes & Notifications' : 'Alerts & Notifications',
            icon: Badge.count(
              count: unreadNotifs,
              isLabelVisible: unreadNotifs > 0,
              backgroundColor: const Color(0xFFE67E22),
              child: const Icon(Icons.notifications),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              _loadFarmerData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: locale.isFrench ? 'Actualiser' : 'Refresh Dashboard',
            onPressed: _loadFarmerData,
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
          indicatorColor: const Color(0xFFE67E22),
          indicatorWeight: 3,
          tabs: [
            Tab(icon: const Icon(Icons.agriculture), text: locale.tr('tab_farms')),
            Tab(icon: const Icon(Icons.sensors), text: locale.tr('tab_iot')),
            Tab(icon: const Icon(Icons.warning_amber), text: locale.tr('tab_alerts')),
            Tab(icon: const Icon(Icons.inventory), text: locale.tr('tab_products')),
            Tab(icon: const Icon(Icons.shopping_basket), text: locale.tr('tab_orders')),
            if (isManager) ...[
              Tab(
                icon: const Icon(Icons.group),
                text: locale.isFrench ? 'Éleveurs' : 'Farmers',
              ),
              Tab(
                icon: const Icon(Icons.two_wheeler),
                text: locale.isFrench ? 'Livreurs' : 'Couriers',
              ),
            ],
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
                if (isManager) ...[
                  _buildFarmersManagementTab(),
                  _buildCouriersManagementTab(),
                ],
              ],
            ),
    );
  }

  Widget _buildFarmsTab() {
    final locale = Provider.of<LocaleProvider>(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFarmDialog,
        backgroundColor: const Color(0xFF0D7A57),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFarmerData,
        child: _farms.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        locale.isFrench
                            ? 'Aucune ferme enregistrée. Cliquez sur + pour ajouter.'
                            : 'No farms registered yet. Click + to add your poultry farm.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _farms.length,
                itemBuilder: (ctx, idx) {
                  final f = _farms[idx];
                  final farmBg = ProductHelper.getFarmBackground(idx);

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _showFarmDetailsDialog(f),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Farm header banner with unique realistic background photo
                          Container(
                            height: 95,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(farmBg),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black.withValues(alpha: 0.1), Colors.black.withValues(alpha: 0.70)],
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              alignment: Alignment.bottomLeft,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    f['name'] ?? 'Farm',
                                    style: const TextStyle(
                                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                                      shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D7A57),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${f['devices']?.length ?? 0} IoT Clusters',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (f['farmId'] != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF81C784)),
                                    ),
                                    child: Text(
                                      'ID: ${f['farmId']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                                Text('📍 ${f['location'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text('🐔 ${locale.tr('capacity')}: ${f['currentPoultryCount'] ?? 0} / ${f['capacity'] ?? 0} birds'),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _showEditFarmDialog(f),
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: Text(locale.tr('edit_farm')),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blue.shade700,
                                          side: BorderSide(color: Colors.blue.shade700)),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _confirmDeleteFarm(f),
                                      icon: const Icon(Icons.delete_outline, size: 16),
                                      label: Text(locale.tr('delete_farm')),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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

  void _showEditFarmDialog(dynamic f) {
    final nameCtrl = TextEditingController(text: f['name']);
    final locCtrl = TextEditingController(text: f['location']);
    final capCtrl = TextEditingController(text: '${f['capacity'] ?? 0}');
    final countCtrl = TextEditingController(text: '${f['currentPoultryCount'] ?? 0}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Farm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Farm Name')),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location')),
              TextField(controller: capCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Capacity (birds)')),
              TextField(controller: countCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Current Poultry Count')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.api.updateFarm(f['id'], {
                'name': nameCtrl.text,
                'location': locCtrl.text,
                'capacity': int.tryParse(capCtrl.text) ?? 0,
                'currentPoultryCount': int.tryParse(countCtrl.text) ?? 0,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              _loadFarmerData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteFarm(dynamic f) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Farm'),
        content: Text('Are you sure you want to delete "${f['name']}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await auth.api.deleteFarm(f['id']);
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              _loadFarmerData();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Farm deleted'), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
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
      body: RefreshIndicator(
        onRefresh: _loadFarmerData,
        child: _devices.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const Center(child: Text('No IoT devices registered. Pull down to refresh or click + to add.')),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
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
                                  activeThumbColor: Colors.green,
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
    final locale = Provider.of<LocaleProvider>(context);
    final aiNotifs = _notifications.where((n) => n['type'] == 'ai_alert').toList();
    final allNotifsCount = _notifications.length;

    return RefreshIndicator(
      onRefresh: _loadFarmerData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Responsive Quick-Action Banner to open Notifications Screen
          Card(
            color: const Color(0xFF0D7A57).withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF0D7A57), width: 1)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Color(0xFF0D7A57), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale.isFrench ? 'Centre d\'alertes et notifications' : 'Alert & Notification Center',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          locale.isFrench ? '$allNotifsCount notification(s) au total' : '$allNotifsCount total notifications recorded',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                      _loadFarmerData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D7A57),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(locale.isFrench ? 'Voir tout' : 'View All'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (aiNotifs.isEmpty)
            Card(
              elevation: 0,
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      locale.isFrench ? 'Tout va bien dans vos élevages !' : 'All Flocks Healthy!',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locale.isFrench
                          ? 'Aucune anomalie sanitaire détectée par le modèle IA.'
                          : 'No health anomalies or disease risk detected by the AI monitoring system.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            )
          else
            ...aiNotifs.map((item) {
              return Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade200)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showAlertDetailsDialog(item),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.warning, color: Colors.white)),
                    title: Text(item['title'] ?? 'AI Health Alert', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item['message'] ?? ''),
                    trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFarmerData,
        child: _products.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const Center(child: Text('No inventory products listed. Pull down to refresh or click + to add.')),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _products.length,
                itemBuilder: (ctx, idx) {
                  final p = _products[idx];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showEditProductDialog(p),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ProductHelper.buildProductImage(
                            p,
                            width: 54,
                            height: 54,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p['name'] ?? 'Product',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D7A57).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                p['category'] ?? '',
                                style: const TextStyle(color: Color(0xFF0D7A57), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              '${p['price']} FCFA | Stock: ${p['stockQuantity']} ${p['unit']}',
                              style: const TextStyle(color: Color(0xFF0D7A57), fontWeight: FontWeight.bold),
                            ),
                            if (p['imageUrl'] != null && (p['imageUrl'] as String).isNotEmpty)
                              Text(
                                p['imageUrl'].toString().contains('product_') && !p['imageUrl'].toString().contains('/uploads/products/product_')
                                    ? 'Uploaded photo'
                                    : 'Backend image',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.teal),
                              tooltip: 'Edit product & image',
                              onPressed: () => _showEditProductDialog(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete product',
                              onPressed: () => _confirmDeleteProduct(p),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    final locale = Provider.of<LocaleProvider>(context);
    return RefreshIndicator(
      onRefresh: _loadFarmerData,
      child: _orders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(child: Text(locale.isFrench ? 'Aucune commande reçue pour le moment.' : 'No customer orders received yet.')),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (ctx, idx) {
                final o = _orders[idx];
                final delivery = o['delivery'];
                final driverName = delivery?['deliveryPerson']?['name'];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showOrderDetailsDialog(o),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Order #${o['id'].toString().substring(0, 8)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              PopupMenuButton<String>(
                                tooltip: locale.isFrench ? 'Modifier le statut de la commande' : 'Change Order Status',
                                onSelected: (status) async {
                                  final auth = Provider.of<AuthProvider>(context, listen: false);
                                  final scaffold = ScaffoldMessenger.of(context);
                                  try {
                                    await auth.api.updateOrderStatus(o['id'].toString(), status);
                                    if (!mounted) return;
                                    _loadFarmerData();
                                    scaffold.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          locale.isFrench
                                              ? 'Statut de la commande #${o['id'].toString().substring(0, 8)} mis à jour : ${status.toUpperCase()}'
                                              : 'Order #${o['id'].toString().substring(0, 8)} status updated to ${status.toUpperCase()}',
                                        ),
                                        backgroundColor: const Color(0xFF0D7A57),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  } catch (e) {
                                    scaffold.showSnackBar(
                                      SnackBar(
                                        content: Text('Error updating status: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  'pending',
                                  'accepted',
                                  'rejected',
                                  'in_transit',
                                  'delivered',
                                  'cancelled'
                                ].map((s) {
                                  final isCurrent = s.toLowerCase() == o['status']?.toString().toLowerCase();
                                  return PopupMenuItem<String>(
                                    value: s,
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCurrent ? Icons.check_circle : Icons.radio_button_unchecked,
                                          size: 16,
                                          color: isCurrent ? const Color(0xFF0D7A57) : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          s.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                            color: isCurrent ? const Color(0xFF0D7A57) : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getOrderStatusColor(o['status']?.toString()).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _getOrderStatusColor(o['status']?.toString()),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${o['status'] ?? 'pending'}'.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _getOrderStatusColor(o['status']?.toString()),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.edit_note,
                                        size: 15,
                                        color: _getOrderStatusColor(o['status']?.toString()),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Customer: ${o['customer']?['name'] ?? 'Customer'} | Total: ${o['totalAmount']} FCFA'),
                          Text('Payment: ${o['paymentStatus']} | Delivery Status: ${delivery?['status'] ?? 'unassigned'}'),
                          if (driverName != null) Text('Assigned Courier: $driverName'),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _showAssignDeliveryDialog(delivery?['id']?.toString() ?? o['id'].toString()),
                                icon: const Icon(Icons.delivery_dining, size: 16),
                                label: Text(
                                  driverName == null
                                      ? (locale.isFrench ? 'Assigner un livreur' : 'Assign Courier')
                                      : (locale.isFrench ? 'Réassigner: $driverName' : 'Reassign: $driverName'),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAssignDeliveryDialog(String deliveryOrOrderId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context, listen: false);

    // Immediate visual feedback during driver fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      ),
    );

    List<dynamic> drivers = [];
    try {
      drivers = await auth.api.getDeliveryDrivers();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading couriers: $e'), backgroundColor: Colors.red),
      );
      return;
    }

    if (mounted) Navigator.pop(context); // Dismiss loading indicator
    if (!mounted) return;

    if (drivers.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.purple),
              const SizedBox(width: 8),
              Text(locale.isFrench ? 'Aucun livreur disponible' : 'No Couriers Available'),
            ],
          ),
          content: Text(
            locale.isFrench
                ? 'Aucun livreur n\'est actuellement disponible sur la plateforme.'
                : 'No delivery couriers are currently registered on the platform.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    String selectedDriverId = drivers.first['id'].toString();
    bool isAssigning = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.delivery_dining, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locale.isFrench ? 'Assigner la livraison' : 'Assign Delivery Courier',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.isFrench
                    ? 'Sélectionnez le livreur. Il recevra une notification instantanée avec les détails de la commande.'
                    : 'Select a courier. They will receive an instant notification with order details.',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedDriverId,
                decoration: InputDecoration(
                  labelText: locale.isFrench ? 'Sélectionner le livreur' : 'Select Delivery Person',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_pin, color: Colors.purple),
                ),
                items: drivers.map<DropdownMenuItem<String>>((d) {
                  return DropdownMenuItem(
                    value: d['id'].toString(),
                    child: Text('${d['name']} (${d['phone'] ?? d['email'] ?? 'Novara Courier'})'),
                  );
                }).toList(),
                onChanged: isAssigning ? null : (val) => setDialogState(() => selectedDriverId = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isAssigning ? null : () => Navigator.pop(ctx),
              child: Text(locale.isFrench ? 'Annuler' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: isAssigning ? null : () async {
                setDialogState(() => isAssigning = true);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await auth.api.assignDelivery(deliveryOrOrderId, selectedDriverId);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!mounted) return;
                  _loadFarmerData();

                  final selectedDriver = drivers.firstWhere(
                    (d) => d['id'].toString() == selectedDriverId,
                    orElse: () => {'name': 'Courier'},
                  );

                  scaffoldMessenger.hideCurrentSnackBar();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        locale.isFrench
                            ? 'Livraison assignée à ${selectedDriver['name']} ! Le livreur a été notifié.'
                            : 'Delivery assigned to ${selectedDriver['name']}! Courier has been notified.',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  setDialogState(() => isAssigning = false);
                  if (ctx.mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
              ),
              child: isAssigning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(locale.isFrench ? 'Assigner' : 'Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmersManagementTab() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadFarmerData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                locale.isFrench ? 'Gestion des Éleveurs' : 'Farmers Management',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showCreateFarmerDialog,
                    icon: const Icon(Icons.person_add, size: 14),
                    label: Text(
                      locale.isFrench ? 'Créer éleveur' : 'New Farmer',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D7A57),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _pendingFarmers.isNotEmpty ? Colors.amber.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _pendingFarmers.isNotEmpty ? Colors.amber.shade700 : Colors.green.shade700,
                      ),
                    ),
                    child: Text(
                      '${_pendingFarmers.length} ${locale.isFrench ? 'En attente' : 'Pending'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _pendingFarmers.isNotEmpty ? Colors.amber.shade900 : Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            locale.isFrench
                ? 'En tant que chef d\'exploitation, vous validez ou refusez les demandes des éleveurs, et vous pouvez créer directement un compte éleveur.'
                : 'As Farm Manager, you review and approve farmer applications, and can directly create farmer accounts.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Pending Applications Section
          Text(
            locale.isFrench ? 'Demandes en attente d\'approbation' : 'Pending Farmer Applications',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D7A57)),
          ),
          const SizedBox(height: 8),
          if (_pendingFarmers.isEmpty)
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    locale.isFrench ? 'Aucune candidature d\'éleveur en attente.' : 'No pending farmer applications.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ..._pendingFarmers.map((f) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.amber.shade400, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.amber.shade100,
                            child: Icon(Icons.person, color: Colors.amber.shade900),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f['name'] ?? 'Farmer Applicant', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(f['email'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                if (f['phone'] != null) Text('Phone: ${f['phone']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amber)),
                            child: const Text('PENDING', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (f['cniNumber'] != null)
                            Text('CNI: ${f['cniNumber']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D7A57))),
                          if (f['professionalLicenseNumber'] != null && f['professionalLicenseNumber'].toString().isNotEmpty)
                            Text('License: ${f['professionalLicenseNumber']}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          if (f['farmerId'] != null)
                            Text('ID: ${f['farmerId']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _promptRejectFarmer(f['id'], f['name']),
                            icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                            label: Text(locale.isFrench ? 'Refuser' : 'Decline', style: const TextStyle(color: Colors.red, fontSize: 12)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await auth.api.approveFarmer(f['id']);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(locale.isFrench ? 'Éleveur approuvé avec succès !' : 'Farmer approved successfully!'),
                                      backgroundColor: const Color(0xFF0D7A57),
                                    ),
                                  );
                                  _loadFarmerData();
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: Text(locale.isFrench ? 'Valider' : 'Approve', style: const TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D7A57), foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),
          // Active Farmers Directory
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                locale.isFrench ? 'Répertoire des Éleveurs Actifs' : 'Active Farmers Directory',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _showCreateFarmerDialog,
                icon: const Icon(Icons.person_add, size: 16, color: Color(0xFF0D7A57)),
                label: Text(
                  locale.isFrench ? 'Ajouter éleveur' : 'Add Farmer',
                  style: const TextStyle(color: Color(0xFF0D7A57), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_managedFarmers.isEmpty)
            Center(child: Text(locale.isFrench ? 'Aucun éleveur actif.' : 'No active farmers.'))
          else
            ..._managedFarmers.map((f) {
              final farmCount = f['farms']?.length ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.green.shade100, child: const Icon(Icons.agriculture, color: Color(0xFF0D7A57))),
                  title: Text(f['name'] ?? 'Farmer'),
                  subtitle: Text('${f['email']} | Phone: ${f['phone'] ?? 'N/A'}\nFarms: $farmCount | CNI: ${f['cniNumber'] ?? 'N/A'}'),
                  isThreeLine: true,
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showCreateFarmerDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'Farmer123!');
    final phoneCtrl = TextEditingController();
    final cniCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final farmNameCtrl = TextEditingController();
    final farmLocCtrl = TextEditingController();
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D7A57).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_alt_1, color: Color(0xFF0D7A57), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  locale.isFrench ? 'Créer un Compte Éleveur' : 'Create Farmer Account',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.isFrench
                        ? 'Créez directement un compte pour un éleveur sous votre supervision.'
                        : 'Directly provision a farmer account under your farm management.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: locale.isFrench ? 'Nom complet de l\'éleveur *' : 'Farmer Full Name *',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: locale.isFrench ? 'Adresse Email *' : 'Email Address *',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: locale.isFrench ? 'Mot de passe temporaire *' : 'Temporary Password *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: locale.isFrench ? 'Numéro de téléphone' : 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      hintText: '6XXXXXXXX',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cniCtrl,
                    decoration: InputDecoration(
                      labelText: locale.isFrench ? 'Numéro CNI' : 'National ID (CNI)',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: locale.isFrench ? 'Ville / Adresse' : 'City / Location',
                      prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  Text(
                    locale.isFrench ? 'Ferme associée (optionnel)' : 'Associated Farm (optional)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D7A57)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: farmNameCtrl,
                    decoration: InputDecoration(
                      labelText: locale.isFrench ? 'Nom de la ferme' : 'Farm Name',
                      prefixIcon: const Icon(Icons.agriculture, size: 20),
                      hintText: locale.isFrench ? 'Ex: Ferme Avicole Espoir' : 'Ex: Hope Poultry Farm',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: farmLocCtrl,
                    decoration: InputDecoration(
                      labelText: locale.isFrench ? 'Localisation de la ferme' : 'Farm Location',
                      prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
                      hintText: locale.isFrench ? 'Ex: Obala, Région du Centre' : 'Ex: Obala, Centre Region',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: Text(locale.isFrench ? 'Annuler' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final email = emailCtrl.text.trim();
                      final password = passCtrl.text.trim();

                      if (name.isEmpty || email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(locale.isFrench
                                ? 'Veuillez remplir le nom, l\'email et le mot de passe.'
                                : 'Please fill in name, email, and password.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDlgState(() => isSaving = true);
                      final auth = Provider.of<AuthProvider>(context, listen: false);

                      try {
                        final res = await auth.api.createFarmer({
                          'name': name,
                          'email': email,
                          'password': password,
                          'phone': phoneCtrl.text.trim(),
                          'cniNumber': cniCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'farmName': farmNameCtrl.text.trim(),
                          'farmLocation': farmLocCtrl.text.trim(),
                        });

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;

                        final farmerId = res['farmer']?['farmerId'] ?? '';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(locale.isFrench
                                ? 'Compte éleveur créé avec succès ! ($farmerId)'
                                : 'Farmer account created successfully! ($farmerId)'),
                            backgroundColor: const Color(0xFF0D7A57),
                          ),
                        );

                        _loadFarmerData();
                      } catch (e) {
                        setDlgState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7A57),
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(locale.isFrench ? 'Créer l\'éleveur' : 'Create Farmer'),
            ),
          ],
        ),
      ),
    );
  }

  void _promptRejectFarmer(String farmerId, String? farmerName) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Decline Farmer Application: ${farmerName ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide the reason for declining this farmer application:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. CNI unverified, farm location not validated...',
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
                await auth.api.rejectFarmer(farmerId, reason.isNotEmpty ? reason : 'Application declined by Farm Manager');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Farmer application declined.'), backgroundColor: Colors.orange),
                  );
                  _loadFarmerData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  Widget _buildCouriersManagementTab() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadFarmerData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                locale.isFrench ? 'Gestion des Livreurs' : 'Couriers Management',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _pendingCouriers.isNotEmpty ? Colors.amber.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pendingCouriers.isNotEmpty ? Colors.amber.shade700 : Colors.green.shade700,
                  ),
                ),
                child: Text(
                  '${_pendingCouriers.length} ${locale.isFrench ? 'En attente' : 'Pending'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _pendingCouriers.isNotEmpty ? Colors.amber.shade900 : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            locale.isFrench
                ? 'En tant que chef d\'exploitation, vous validez ou refusez les demandes des livreurs.'
                : 'As Farm Manager, you review and validate or decline logistics courier applications.',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Pending Courier Applications Section
          Text(
            locale.isFrench ? 'Candidatures de Livreurs en attente' : 'Pending Courier Applications',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D7A57)),
          ),
          const SizedBox(height: 8),
          if (_pendingCouriers.isEmpty)
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    locale.isFrench ? 'Aucune candidature de livreur en attente.' : 'No pending courier applications.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ..._pendingCouriers.map((d) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.amber.shade400, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.amber.shade100,
                            child: Icon(Icons.two_wheeler, color: Colors.amber.shade900),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['name'] ?? 'Courier Applicant', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(d['email'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                if (d['phone'] != null) Text('Phone: ${d['phone']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.amber)),
                            child: const Text('PENDING', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: [
                          if (d['cniNumber'] != null)
                            Text('CNI: ${d['cniNumber']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D7A57))),
                          if (d['vehicleType'] != null)
                            Text('Vehicle: ${d['vehicleType']}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          if (d['vehiclePlateNumber'] != null)
                            Text('Plate: ${d['vehiclePlateNumber']}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          if (d['deliveryPersonId'] != null)
                            Text('ID: ${d['deliveryPersonId']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _promptRejectCourier(d['id'], d['name']),
                            icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                            label: Text(locale.isFrench ? 'Refuser' : 'Decline', style: const TextStyle(color: Colors.red, fontSize: 12)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await auth.api.approveDeliveryPerson(d['id']);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(locale.isFrench ? 'Livreur approuvé avec succès !' : 'Courier approved successfully!'),
                                      backgroundColor: const Color(0xFF0D7A57),
                                    ),
                                  );
                                  _loadFarmerData();
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: Text(locale.isFrench ? 'Valider' : 'Approve', style: const TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D7A57), foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),
          // Active Couriers Directory
          Text(
            locale.isFrench ? 'Répertoire des Livreurs Actifs' : 'Active Couriers Directory',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_managedCouriers.isEmpty)
            Center(child: Text(locale.isFrench ? 'Aucun livreur actif.' : 'No active couriers.'))
          else
            ..._managedCouriers.map((d) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.delivery_dining, color: Colors.blue)),
                  title: Text(d['name'] ?? 'Courier'),
                  subtitle: Text('${d['email']} | Phone: ${d['phone'] ?? 'N/A'}\nVehicle: ${d['vehicleType'] ?? 'N/A'} (${d['vehiclePlateNumber'] ?? 'N/A'})'),
                  isThreeLine: true,
                ),
              );
            }),
        ],
      ),
    );
  }

  void _promptRejectCourier(String courierId, String? courierName) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Decline Courier Application: ${courierName ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide the reason for declining this courier application:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Invalid license, plate number mismatch...',
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
                await auth.api.rejectDeliveryPerson(courierId, reason.isNotEmpty ? reason : 'Application declined by Farm Manager');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Courier application declined.'), backgroundColor: Colors.orange),
                  );
                  _loadFarmerData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }
}
