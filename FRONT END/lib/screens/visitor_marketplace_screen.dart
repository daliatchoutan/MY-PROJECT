import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/locale_provider.dart';
import '../widgets/language_switcher.dart';
import '../utils/product_helper.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';

class VisitorMarketplaceScreen extends StatefulWidget {
  const VisitorMarketplaceScreen({super.key});

  @override
  State<VisitorMarketplaceScreen> createState() => _VisitorMarketplaceScreenState();
}

class _VisitorMarketplaceScreenState extends State<VisitorMarketplaceScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
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
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final backendProducts = await ApiService().getProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );

      final combined = List<dynamic>.from(backendProducts);
      // If backend has few or no products, supplement with catalog items matching filter
      for (final def in _catalogDefaults) {
        if (!combined.any((p) => p['name'] == def['name'])) {
          if (_selectedCategory == 'All' || def['category'] == _selectedCategory) {
            combined.add(def);
          }
        }
      }

      if (mounted) {
        setState(() {
          _products = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to catalog defaults
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

  void _promptAuthDialog(String actionName) {
    final locale = Provider.of<LocaleProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFF0D7A57)),
            const SizedBox(width: 8),
            Text(locale.tr('sign_in')),
          ],
        ),
        content: Text(locale.tr('visitor_order_prompt')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: Text(locale.tr('sign_in')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D7A57), foregroundColor: Colors.white),
            child: Text(locale.tr('create_account')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset('assets/images/novara_logo.jpg', width: 30, height: 30, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            Text(locale.tr('role_visitor')),
          ],
        ),
        actions: [
          const LanguageSwitcher(isLight: true),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            icon: const Icon(Icons.login, color: Colors.white, size: 18),
            label: Text(locale.tr('sign_in'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF0D7A57), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locale.tr('visitor_banner'),
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _promptAuthDialog('place orders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7A57),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(locale.tr('create_account'), style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Category Selector
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
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                      _loadProducts();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
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
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['name'] ?? 'Product',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        p['farm']?['name'] ?? 'Farm Fresh',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${p['price']} FCFA',
                                        style: const TextStyle(
                                          color: Color(0xFF0D7A57),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => _promptAuthDialog('purchase ${p['name']}'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0D7A57),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text(locale.tr('order_items'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}
