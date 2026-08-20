import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../notifications_screen.dart';
import '../auth/login_screen.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Live Poultry', 'Eggs', 'Meat', 'Feed'];

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
      final products = await auth.api.getProducts(
        search: _searchQuery,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
      final orders = await auth.api.getOrders();

      if (mounted) {
        setState(() {
          _products = products;
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCartSheet() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final addressCtrl = TextEditingController(text: '123 Main Street, Market District');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Shopping Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              if (cart.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('Your cart is empty.')),
                )
              else ...[
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: cart.items.values.map((item) {
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('\$${item.price} x ${item.quantity}'),
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
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('\$${cart.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    try {
                      await auth.api.createOrder(cart.toApiFormat(), addressCtrl.text);
                      cart.clear();
                      Navigator.pop(ctx);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Checkout & Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poultry Marketplace'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _showCartSheet,
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.storefront), text: 'Browse Marketplace'),
            Tab(icon: Icon(Icons.history), text: 'My Orders & Tracking'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMarketplaceTab(),
                _buildOrdersTab(),
              ],
            ),
    );
  }

  Widget _buildMarketplaceTab() {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              _searchQuery = val;
              _loadData();
            },
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _categories.map((cat) {
              final selected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  selectedColor: Colors.green.shade700,
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                  onSelected: (val) {
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
              ? const Center(child: Text('No products found.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (ctx, idx) {
                    final p = _products[idx];
                    return Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                color: Colors.green.shade50,
                                child: const Center(
                                  child: Icon(Icons.egg_outlined, size: 48, color: Colors.green),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(p['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(p['farm']?['name'] ?? 'Farm', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('\$${p['price']}', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
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
                                    SnackBar(content: Text('${p['name']} added to cart!'), duration: const Duration(seconds: 1)),
                                  );
                                },
                                icon: const Icon(Icons.add_shopping_cart, size: 16),
                                label: const Text('Add to Cart'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (ctx, idx) {
        final o = _orders[idx];
        final status = o['status'] ?? 'pending';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${o['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Chip(
                      label: Text(status.toUpperCase()),
                      backgroundColor: status == 'delivered' ? Colors.green.shade100 : Colors.amber.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Total Amount: \$${o['totalAmount']}'),
                Text('Shipping Address: ${o['shippingAddress']}'),
                const Divider(),
                Text('Delivery Status: ${o['delivery']?['status'] ?? 'unassigned'}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
