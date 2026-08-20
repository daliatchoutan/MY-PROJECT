import 'package:flutter/material.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  int quantity;
  final String unit;
  final String? imageUrl;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
    this.imageUrl,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  void addItem({
    required String productId,
    required String name,
    required double price,
    required String unit,
    String? imageUrl,
  }) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity += 1;
    } else {
      _items[productId] = CartItem(
        productId: productId,
        name: name,
        price: price,
        quantity: 1,
        unit: unit,
        imageUrl: imageUrl,
      );
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        _items.remove(productId);
      } else {
        _items[productId]!.quantity = quantity;
      }
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toApiFormat() {
    return _items.values.map((item) => {
      'productId': item.productId,
      'quantity': item.quantity,
    }).toList();
  }
}
