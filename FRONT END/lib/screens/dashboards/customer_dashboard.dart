import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/language_switcher.dart';
import '../../utils/product_helper.dart';
import '../notifications_screen.dart';
import '../profile_screen.dart';
import '../welcome_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Live Poultry', 'Eggs', 'Meat', 'Feed'];

  static final List<Map<String, dynamic>> _catalogDefaults = [
    {
      'id': 'cat-1',
      'name': 'Day-old Chicks (Pack of 50)',
      'category': 'Live Poultry',
      'price': '35000',
      'unit': 'pack',
      'description': 'Vaccinated day-old broiler chicks, high vitality',
      'farm': {'name': 'Green Hills Hatchery'}
    },
    {
      'id': 'cat-2',
      'name': 'Mature Rooster (Cockerel)',
      'category': 'Live Poultry',
      'price': '9000',
      'unit': 'bird',
      'description': 'Free-range mature rooster, strong and healthy',
      'farm': {'name': 'Sunrise Eco Farm'}
    },
    {
      'id': 'cat-3',
      'name': 'Live Broiler Chicken',
      'category': 'Live Poultry',
      'price': '4500',
      'unit': 'bird',
      'description': 'Healthy 2.5kg commercial broiler meat chicken',
      'farm': {'name': 'AgriTech Agro Farm'}
    },
    {
      'id': 'cat-4',
      'name': 'Layer Hen (Point of Lay)',
      'category': 'Live Poultry',
      'price': '6000',
      'unit': 'bird',
      'description': 'Rhode Island Red point of lay hens, ready for egg production',
      'farm': {'name': 'Valley Pastures'}
    },
    {
      'id': 'cat-5',
      'name': 'Farm-Fresh Whole Chicken',
      'category': 'Meat',
      'price': '4800',
      'unit': 'chicken',
      'description': 'Dressed, cleaned whole poultry chicken ready for cooking',
      'farm': {'name': 'Green Hills Poultry'}
    },
    {
      'id': 'cat-6',
      'name': 'Fresh Chicken Breast & Cuts',
      'category': 'Meat',
      'price': '3800',
      'unit': 'kg',
      'description': 'Fresh boneless chicken fillets and cut portions',
      'farm': {'name': 'Sunrise Poultry'}
    },
    {
      'id': 'cat-7',
      'name': 'Organic Brown Eggs (Tray of 30)',
      'category': 'Eggs',
      'price': '3500',
      'unit': 'tray',
      'description': 'Fresh free-range pasture raised table eggs',
      'farm': {'name': 'Valley Pastures'}
    },
    {
      'id': 'cat-8',
      'name': 'Poultry Starter Mash & Feed (25kg)',
      'category': 'Feed',
      'price': '14500',
      'unit': 'bag',
      'description': 'Balanced nutrient-dense chicken feed for growth and laying',
      'farm': {'name': 'AgriTech Mills'}
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final backendProducts = await auth.api.getProducts(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );

      final combined = List<dynamic>.from(backendProducts);
      for (final def in _catalogDefaults) {
        if (!combined.any((p) => p['name'] == def['name'])) {
          if (_selectedCategory == 'All' || def['category'] == _selectedCategory) {
            if (_searchQuery.isEmpty || def['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())) {
              combined.add(def);
            }
          }
        }
      }

      final orders = await auth.api.getOrders();
      if (mounted) {
        setState(() {
          _products = combined;
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      final filtered = _selectedCategory == 'All'
          ? _catalogDefaults
          : _catalogDefaults.where((p) => p['category'] == _selectedCategory).toList();
      if (mounted) {
        setState(() {
          _products = filtered;
          _isLoading = false;
        });
      }
    }
  }

  void _showCartSheet() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final addressCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 24, left: 24, right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(locale.tr('my_cart'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              if (cart.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(locale.tr('cart_empty'))),
                )
              else ...[
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: cart.items.values.map((item) {
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('${item.price.toStringAsFixed(0)} FCFA × ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                cart.updateQuantity(item.productId, item.quantity - 1);
                                setSheetState(() {});
                              },
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                cart.updateQuantity(item.productId, item.quantity + 1);
                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: locale.tr('delivery_address'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${locale.tr('total')}:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${cart.totalAmount.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontSize: 20, color: Color(0xFF0D7A57), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (addressCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(locale.isFrench ? 'Veuillez saisir une adresse' : 'Please enter a delivery address')),
                      );
                      return;
                    }
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      final orderRes = await auth.api.createOrder(
                        cart.toApiFormat(), addressCtrl.text.trim(),
                      );
                      cart.clear();
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!mounted) return;
                      _loadData();
                      _showPaymentDialog(
                        orderRes['order']['id'], orderRes['order']['totalAmount']);
                    } catch (e) {
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7A57),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(locale.tr('place_order'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(String orderId, dynamic amount) {
    String selectedMethod = 'MTN Mobile Money';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Initiate Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: $amount FCFA',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D7A57))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedMethod,
                decoration: const InputDecoration(labelText: 'Payment Channel', border: OutlineInputBorder()),
                items: ['MTN Mobile Money', 'Orange Money', 'Credit / Debit Card']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedMethod = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Pay Later')),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                await auth.api.initiatePayment(orderId, selectedMethod);
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                _loadData();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Payment of $amount FCFA confirmed via $selectedMethod!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D7A57), foregroundColor: Colors.white),
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showModifyOrderDialog(dynamic order) {
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final addressCtrl = TextEditingController(text: order['shippingAddress'] ?? '');
    final notesCtrl = TextEditingController(text: order['notes'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.tr('modify_order')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: addressCtrl,
              decoration: InputDecoration(
                  labelText: locale.tr('delivery_address'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                  labelText: locale.isFrench ? 'Notes de commande (optionnel)' : 'Order Notes (optional)',
                  border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(locale.isFrench ? 'Annuler' : 'Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await auth.api.updateOrder(order['id'], {
                  'shippingAddress': addressCtrl.text.trim(),
                  'notes': notesCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                _loadData();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(locale.isFrench ? 'Commande mise à jour' : 'Order updated successfully'), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7A57), foregroundColor: Colors.white),
            child: Text(locale.isFrench ? 'Enregistrer' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmCancelOrder(dynamic order) {
    final locale = Provider.of<LocaleProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale.tr('cancel_order')),
        content: Text(locale.isFrench
            ? 'Voulez-vous vraiment annuler la commande #${order['id'].toString().substring(0, 8)} ? Le stock sera restauré.'
            : 'Are you sure you want to cancel Order #${order['id'].toString().substring(0, 8)}? Stock will be restored.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(locale.isFrench ? 'Non, garder' : 'No, Keep It')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await auth.api.cancelOrder(order['id']);
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                _loadData();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(locale.isFrench ? 'Commande annulée' : 'Order cancelled'), backgroundColor: Colors.orange),
                );
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(locale.isFrench ? 'Oui, Annuler' : 'Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = Provider.of<CartProvider>(context);
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
            Text(locale.tr('role_customer')),
          ],
        ),
        actions: [
          const LanguageSwitcher(isLight: true),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              backgroundImage: (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                  ? Text((auth.user?['name'] ?? 'C')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF0D7A57)))
                  : null,
            ),
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _showCartSheet,
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFE67E22), shape: BoxShape.circle),
                    child: Text('${cart.itemCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WelcomeScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFE67E22),
          indicatorWeight: 3,
          tabs: [
            Tab(icon: const Icon(Icons.storefront), text: locale.tr('tab_products')),
            Tab(icon: const Icon(Icons.track_changes), text: locale.tr('tab_orders')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildMarketplaceTab(), _buildOrdersTab()],
            ),
    );
  }

  Widget _buildMarketplaceTab() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: locale.tr('search_products'),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
            onChanged: (val) {
              _searchQuery = val;
              _loadData();
            },
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _categories.map((cat) {
              final selected = _selectedCategory == cat;
              String localizedCat = cat;
              if (cat == 'All') localizedCat = locale.tr('all');
              if (cat == 'Live Poultry') localizedCat = locale.tr('live_poultry');
              if (cat == 'Eggs') localizedCat = locale.tr('eggs');
              if (cat == 'Meat') localizedCat = locale.tr('meat');
              if (cat == 'Feed') localizedCat = locale.tr('feed');

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(localizedCat),
                  selected: selected,
                  selectedColor: const Color(0xFF0D7A57),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) {
                    setState(() => _selectedCategory = cat);
                    _loadData();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _products.isEmpty
              ? Center(child: Text(locale.isFrench ? 'Aucun produit disponible.' : 'No products available.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.66,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (ctx, idx) {
                    final p = _products[idx];

                    return Card(
                      elevation: 3,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ProductHelper.buildProductImage(
                                  p,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.20)],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE67E22),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p['category'] ?? '',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name'] ?? 'Product',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(p['farm']?['name'] ?? 'Farm Fresh',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text('${p['price']} FCFA',
                                    style: const TextStyle(
                                        color: Color(0xFF0D7A57),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      cart.addItem(
                                        productId: p['id'],
                                        name: p['name'],
                                        price: double.parse(p['price'].toString()),
                                        unit: p['unit'] ?? 'unit',
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${p['name']} ${locale.isFrench ? 'ajouté au panier !' : 'added!'}'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add_shopping_cart, size: 14),
                                    label: Text(locale.tr('add_to_cart'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D7A57),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    final locale = Provider.of<LocaleProvider>(context);

    if (_orders.isEmpty) {
      return Center(child: Text(locale.isFrench ? 'Aucune commande reçue pour le moment.' : 'You have no orders yet.'));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (ctx, idx) {
          final o = _orders[idx];
          final status = o['status'] ?? 'pending';
          final payStatus = o['paymentStatus'] ?? 'pending';
          final canModify = status == 'pending';
          final canCancel = !['delivered', 'in_transit', 'cancelled'].contains(status);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order #${o['id'].toString().substring(0, 8)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Chip(
                        label: Text(status.toUpperCase(),
                            style: const TextStyle(fontSize: 11, color: Colors.white)),
                        backgroundColor: status == 'delivered'
                            ? const Color(0xFF0D7A57)
                            : status == 'cancelled'
                                ? Colors.red
                                : const Color(0xFFE67E22),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${locale.tr('total')}: ${o['totalAmount']} FCFA',
                      style: const TextStyle(fontSize: 14)),
                  Text('Payment: ${payStatus.toUpperCase()}',
                      style: TextStyle(
                          fontSize: 13,
                          color: payStatus == 'paid' ? const Color(0xFF0D7A57) : const Color(0xFFE67E22))),
                  const Divider(height: 16),
                  _buildTrackingTimeline(status, o['delivery']?['status']),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (payStatus == 'pending')
                        ElevatedButton.icon(
                          onPressed: () => _showPaymentDialog(o['id'], o['totalAmount']),
                          icon: const Icon(Icons.payment, size: 16),
                          label: Text(locale.tr('pay_now')),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D7A57),
                              foregroundColor: Colors.white),
                        ),
                      if (canModify)
                        OutlinedButton.icon(
                          onPressed: () => _showModifyOrderDialog(o),
                          icon: const Icon(Icons.edit, size: 16),
                          label: Text(locale.tr('modify_order')),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                              side: BorderSide(color: Colors.blue.shade700)),
                        ),
                      if (canCancel)
                        OutlinedButton.icon(
                          onPressed: () => _confirmCancelOrder(o),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: Text(locale.tr('cancel_order')),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red)),
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

  Widget _buildTrackingTimeline(String orderStatus, String? deliveryStatus) {
    int currentStep = 0;
    if (orderStatus == 'accepted') currentStep = 1;
    if (orderStatus == 'in_transit' || deliveryStatus == 'picked_up') currentStep = 2;
    if (orderStatus == 'delivered' || deliveryStatus == 'delivered') currentStep = 3;

    return Row(
      children: [
        _buildNode('Placed', currentStep >= 0),
        _buildLine(currentStep >= 1),
        _buildNode('Accepted', currentStep >= 1),
        _buildLine(currentStep >= 2),
        _buildNode('In Transit', currentStep >= 2),
        _buildLine(currentStep >= 3),
        _buildNode('Delivered', currentStep >= 3),
      ],
    );
  }

  Widget _buildNode(String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: active ? const Color(0xFF0D7A57) : Colors.grey.shade300,
          child: Icon(Icons.check, size: 12, color: active ? Colors.white : Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 9, color: active ? Colors.black : Colors.grey)),
      ],
    );
  }

  Widget _buildLine(bool active) => Expanded(
        child: Container(height: 2, color: active ? const Color(0xFF0D7A57) : Colors.grey.shade300),
      );
}
