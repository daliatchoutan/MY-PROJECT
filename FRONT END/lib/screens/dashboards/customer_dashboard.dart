import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
      'imageUrl': '/uploads/products/product_chicks.jpg',
      'farm': {'name': 'Green Hills Hatchery'}
    },
    {
      'id': 'cat-2',
      'name': 'Mature Rooster (Cockerel)',
      'category': 'Live Poultry',
      'price': '9000',
      'unit': 'bird',
      'description': 'Free-range mature rooster, strong and healthy',
      'imageUrl': '/uploads/products/product_rooster.jpg',
      'farm': {'name': 'Sunrise Eco Farm'}
    },
    {
      'id': 'cat-3',
      'name': 'Live Broiler Chicken',
      'category': 'Live Poultry',
      'price': '4500',
      'unit': 'bird',
      'description': 'Healthy 2.5kg commercial broiler meat chicken',
      'imageUrl': '/uploads/products/product_broiler.jpg',
      'farm': {'name': 'AgriTech Agro Farm'}
    },
    {
      'id': 'cat-4',
      'name': 'Layer Hen (Point of Lay)',
      'category': 'Live Poultry',
      'price': '6000',
      'unit': 'bird',
      'description': 'Rhode Island Red point of lay hens, ready for egg production',
      'imageUrl': '/uploads/products/product_layer.jpg',
      'farm': {'name': 'Valley Pastures'}
    },
    {
      'id': 'cat-5',
      'name': 'Farm-Fresh Whole Chicken',
      'category': 'Meat',
      'price': '4800',
      'unit': 'chicken',
      'description': 'Dressed, cleaned whole poultry chicken ready for cooking',
      'imageUrl': '/uploads/products/product_fresh_chicken.jpg',
      'farm': {'name': 'Green Hills Poultry'}
    },
    {
      'id': 'cat-6',
      'name': 'Fresh Chicken Breast & Cuts',
      'category': 'Meat',
      'price': '3800',
      'unit': 'kg',
      'description': 'Fresh boneless chicken fillets and cut portions',
      'imageUrl': '/uploads/products/product_meat.jpg',
      'farm': {'name': 'Sunrise Poultry'}
    },
    {
      'id': 'cat-7',
      'name': 'Organic Brown Eggs (Tray of 30)',
      'category': 'Eggs',
      'price': '3500',
      'unit': 'tray',
      'description': 'Fresh free-range pasture raised table eggs',
      'imageUrl': '/uploads/products/product_brown_eggs.jpg',
      'farm': {'name': 'Valley Pastures'}
    },
    {
      'id': 'cat-8',
      'name': 'Farm-Fresh Table Eggs (Pack of 12)',
      'category': 'Eggs',
      'price': '1500',
      'unit': 'pack',
      'description': 'Clean washed premium organic farm eggs',
      'imageUrl': '/uploads/products/product_eggs.jpg',
      'farm': {'name': 'Green Hills Poultry'}
    },
    {
      'id': 'cat-9',
      'name': 'Poultry Starter Mash & Feed (25kg)',
      'category': 'Feed',
      'price': '14500',
      'unit': 'bag',
      'description': 'Balanced nutrient-dense chicken feed for growth and laying',
      'imageUrl': '/uploads/products/product_feed.jpg',
      'farm': {'name': 'AgriTech Mills'}
    },
    {
      'id': 'cat-10',
      'name': 'Layer Pellets & Grain Feed (50kg)',
      'category': 'Feed',
      'price': '22000',
      'unit': 'bag',
      'description': 'High-protein grain pellets formulated for optimal egg production',
      'imageUrl': '/uploads/products/product_feed.jpg',
      'farm': {'name': 'Sunrise Agro Mills'}
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

      final combined = <dynamic>[];
      for (final p in backendProducts) {
        if (ProductHelper.matchesCategory(p['category'], _selectedCategory)) {
          combined.add(p);
        }
      }

      for (final def in _catalogDefaults) {
        if (!combined.any((p) => p['name'] == def['name'])) {
          if (ProductHelper.matchesCategory(def['category'], _selectedCategory)) {
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
      final filtered = _catalogDefaults
          .where((p) => ProductHelper.matchesCategory(p['category'], _selectedCategory))
          .where((p) => _searchQuery.isEmpty || p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
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
    final addressCtrl = TextEditingController(text: 'Yaoundé, Cameroon');
    bool isPlacingOrder = false;
    String? addressError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 20, left: 20, right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Color(0xFF0D7A57)),
                      const SizedBox(width: 8),
                      Text(locale.tr('my_cart'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              if (cart.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      Icon(Icons.remove_shopping_cart_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(locale.tr('cart_empty'), style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              else ...[
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: cart.items.values.map((item) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${item.price.toStringAsFixed(0)} FCFA × ${item.quantity}'),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: isPlacingOrder ? null : () {
                                    cart.updateQuantity(item.productId, item.quantity - 1);
                                    setSheetState(() {});
                                  },
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: isPlacingOrder ? null : () {
                                    cart.updateQuantity(item.productId, item.quantity + 1);
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(),
                TextField(
                  controller: addressCtrl,
                  enabled: !isPlacingOrder,
                  onChanged: (val) {
                    if (addressError != null && val.trim().isNotEmpty) {
                      setSheetState(() => addressError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: locale.tr('delivery_address'),
                    hintText: locale.isFrench ? 'Ex: Yaoundé, Bastos' : 'Ex: Yaoundé, Bastos',
                    errorText: addressError,
                    prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0D7A57)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${locale.tr('total')}:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${cart.totalAmount.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontSize: 20, color: Color(0xFF0D7A57), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: isPlacingOrder ? null : () async {
                    final trimmedAddress = addressCtrl.text.trim();
                    if (trimmedAddress.isEmpty) {
                      setSheetState(() {
                        addressError = locale.isFrench
                            ? 'Veuillez saisir une adresse de livraison'
                            : 'Please enter a delivery address';
                      });
                      return;
                    }

                    setSheetState(() {
                      isPlacingOrder = true;
                      addressError = null;
                    });

                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    try {
                      final orderRes = await auth.api.createOrder(
                        cart.toApiFormat(), trimmedAddress,
                      );
                      cart.clear();
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!mounted) return;
                      _loadData();

                      final order = orderRes['order'] ?? orderRes;
                      final orderId = order['id']?.toString() ?? '';
                      final orderTotal = order['totalAmount'] ?? cart.totalAmount;

                      _showPaymentDialog(orderId, orderTotal);
                    } catch (e) {
                      setSheetState(() => isPlacingOrder = false);
                      if (ctx.mounted) {
                        showDialog(
                          context: ctx,
                          builder: (c) => AlertDialog(
                            title: Text(locale.isFrench ? 'Erreur de commande' : 'Order Error'),
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7A57),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isPlacingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(locale.tr('place_order'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(String orderId, dynamic amount) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userPhone = auth.user?['phone']?.toString() ?? '';
    final phoneCtrl = TextEditingController(text: userPhone);
    String selectedMethod = 'MTN Mobile Money';
    bool isProcessing = false;
    final locale = Provider.of<LocaleProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_outline, color: Color(0xFF0D7A57)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locale.isFrench ? 'Paiement DigiPay' : 'DigiPay Checkout',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D7A57).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user, color: Color(0xFF0D7A57), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'DigiPay Mobile Money Gateway',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${locale.tr('total')}: $amount FCFA',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0D7A57)),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedMethod,
                decoration: InputDecoration(
                  labelText: locale.isFrench ? 'Canal de paiement' : 'Payment Channel',
                  border: const OutlineInputBorder(),
                ),
                items: ['MTN Mobile Money', 'Orange Money']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: isProcessing ? null : (val) => setDialogState(() => selectedMethod = val!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: locale.isFrench ? 'Numéro Mobile Money (Push USSD)' : 'Phone for Mobile Money Push',
                  hintText: 'Ex: 237 6XX XXX XXX',
                  prefixIcon: const Icon(Icons.phone_android, color: Color(0xFF0D7A57)),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isProcessing ? null : () => Navigator.pop(ctx),
              child: Text(locale.isFrench ? 'Payer plus tard' : 'Pay Later'),
            ),
            ElevatedButton(
              onPressed: isProcessing ? null : () async {
                final inputPhone = phoneCtrl.text.trim();
                setDialogState(() => isProcessing = true);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  final res = await auth.api.initiatePayment(orderId, selectedMethod, phone: inputPhone);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!mounted) return;
                  _loadData();

                  final paymentUrl = res['paymentUrl']?.toString();
                  final isAwaitingKey = res['isAwaitingKey'] == true;
                  final ref = res['paymentReference']?.toString() ?? '';

                  if (paymentUrl != null && paymentUrl.isNotEmpty) {
                    final uri = Uri.parse(paymentUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }

                  if (mounted && !isAwaitingKey) {
                    _showDigiPayVerifyDialog(orderId, amount, inputPhone);
                  } else if (isAwaitingKey) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          locale.isFrench
                              ? 'Session DigiPay enregistrée ($ref). En attente de DIGIPAY_API_KEY dans le .env backend.'
                              : 'DigiPay session registered ($ref). Awaiting DIGIPAY_API_KEY in backend .env.',
                        ),
                        backgroundColor: const Color(0xFFE67E22),
                      ),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          res['message'] ??
                              (locale.isFrench
                                  ? 'Session DigiPay créée avec succès !'
                                  : 'DigiPay session created successfully!'),
                        ),
                        backgroundColor: const Color(0xFF0D7A57),
                      ),
                    );
                  }
                } catch (e) {
                  setDialogState(() => isProcessing = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7A57),
                foregroundColor: Colors.white,
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(locale.isFrench ? 'Valider et payer' : 'Confirm & Pay'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDigiPayVerifyDialog(String orderId, dynamic amount, [String? phone]) {
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.sync_outlined, color: Color(0xFF0D7A57)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locale.isFrench ? 'Notification Push DigiPay' : 'DigiPay Push Notification',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    ? 'Une notification de paiement Mobile Money a été envoyée sur votre téléphone ${phone != null && phone.isNotEmpty ? "($phone)" : ""}.\nVeuillez consulter votre téléphone et entrer votre code secret Mobile Money pour approuver.'
                    : 'A Mobile Money push request has been sent to your phone ${phone != null && phone.isNotEmpty ? "($phone)" : ""}.\nPlease check your phone and enter your Mobile Money PIN to approve the transaction.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                locale.isFrench
                    ? 'Une fois validé sur votre mobile, cliquez sur "Vérifier le paiement" pour finaliser immédiatement la commande.'
                    : 'Once approved on your phone, tap "Verify Payment" to immediately confirm the order.',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.pop(ctx),
              child: Text(locale.isFrench ? 'Fermer' : 'Close'),
            ),
            ElevatedButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      setDlgState(() => isVerifying = true);
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      try {
                        final res = await auth.api.verifyPayment(orderId);
                        final isPaid = res['isPaid'] == true || res['paymentStatus'] == 'paid';
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!mounted) return;
                        _loadData();

                        scaffoldMessenger.hideCurrentSnackBar();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isPaid
                                  ? (locale.isFrench
                                      ? 'Paiement DigiPay confirmé avec succès !'
                                      : 'DigiPay payment confirmed successfully!')
                                  : (res['message'] ??
                                      (locale.isFrench
                                          ? 'Paiement toujours en attente chez DigiPay'
                                          : 'Payment still pending with DigiPay')),
                            ),
                            backgroundColor: isPaid ? Colors.green : const Color(0xFFE67E22),
                          ),
                        );
                      } catch (err) {
                        setDlgState(() => isVerifying = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(err.toString()), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7A57),
                foregroundColor: Colors.white,
              ),
              child: isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(locale.isFrench ? 'Vérifier le paiement' : 'Verify Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOrderPayment(String orderId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final res = await auth.api.verifyPayment(orderId);
      final isPaid = res['isPaid'] == true || res['paymentStatus'] == 'paid';
      if (!mounted) return;
      _loadData();
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            isPaid
                ? (locale.isFrench ? 'Paiement DigiPay vérifié et confirmé !' : 'DigiPay payment verified and confirmed!')
                : (res['message'] ??
                    (locale.isFrench
                        ? 'Statut DigiPay : En cours de traitement'
                        : 'DigiPay status: Pending verification')),
          ),
          backgroundColor: isPaid ? Colors.green : const Color(0xFFE67E22),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
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
          IconButton(
            icon: cart.itemCount > 0
                ? Badge.count(
                    count: cart.itemCount,
                    backgroundColor: const Color(0xFFE67E22),
                    child: const Icon(Icons.shopping_cart),
                  )
                : const Icon(Icons.shopping_cart),
            tooltip: 'Cart',
            onPressed: _showCartSheet,
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
          height: 46,
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
                  avatar: ClipOval(
                    child: Image.asset(
                      ProductHelper.getCategoryThumbnail(cat),
                      width: 22,
                      height: 22,
                      fit: BoxFit.cover,
                    ),
                  ),
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
                                      final messenger = ScaffoldMessenger.of(context);
                                      messenger.hideCurrentSnackBar();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('${p['name']} ${locale.isFrench ? 'ajouté au panier !' : 'added to cart!'}'),
                                          duration: const Duration(seconds: 3),
                                          action: SnackBarAction(
                                            label: locale.isFrench ? 'VOIR LE PANIER' : 'VIEW CART',
                                            textColor: Colors.amberAccent,
                                            onPressed: _showCartSheet,
                                          ),
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
                      if (payStatus == 'pending') ...[
                        ElevatedButton.icon(
                          onPressed: () => _showPaymentDialog(o['id'], o['totalAmount']),
                          icon: const Icon(Icons.payment, size: 16),
                          label: Text(locale.tr('pay_now')),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D7A57),
                              foregroundColor: Colors.white),
                        ),
                        if (o['paymentReference'] != null)
                          OutlinedButton.icon(
                            onPressed: () => _verifyOrderPayment(o['id']),
                            icon: const Icon(Icons.verified_outlined, size: 16),
                            label: Text(locale.isFrench ? 'Vérifier DigiPay' : 'Verify DigiPay'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0D7A57),
                              side: const BorderSide(color: Color(0xFF0D7A57)),
                            ),
                          ),
                      ],
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
