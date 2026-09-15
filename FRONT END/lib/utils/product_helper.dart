import 'package:flutter/material.dart';
import '../config/api_config.dart';

class ProductHelper {
  static Widget buildProductImage(
    dynamic product, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    final imageUrl = product != null ? (product['imageUrl'] as String?) : null;
    final fallbackAsset = getProductImage(product);

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      final fullUrl = ApiConfig.getImageUrl(imageUrl);
      return Image.network(
        fullUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            fallbackAsset,
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    }

    return Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit,
    );
  }
  static String getProductImage(dynamic product) {
    if (product == null) return 'assets/images/product_chicken.jpg';

    final name = (product['name'] ?? '').toString().toLowerCase();
    final cat = (product['category'] ?? '').toString().toLowerCase();
    final desc = (product['description'] ?? '').toString().toLowerCase();
    final combined = '$name $cat $desc';

    if (combined.contains('chick') || combined.contains('day-old') || combined.contains('poussin')) {
      return 'assets/images/product_chicks.jpg';
    }
    if (combined.contains('rooster') || combined.contains('coq')) {
      return 'assets/images/product_rooster.jpg';
    }
    if (combined.contains('broiler') || combined.contains('chair')) {
      return 'assets/images/product_broiler.jpg';
    }
    if (combined.contains('layer') || combined.contains('pondeuse')) {
      return 'assets/images/product_layer.jpg';
    }
    if (combined.contains('farm-fresh') || combined.contains('fresh chicken') || combined.contains('poulet frais') || combined.contains('whole')) {
      return 'assets/images/product_fresh_chicken.jpg';
    }
    if (combined.contains('egg') || combined.contains('oeuf') || combined.contains('tray')) {
      return 'assets/images/product_eggs.jpg';
    }
    if (combined.contains('meat') || combined.contains('viande') || combined.contains('fillet') || combined.contains('drumstick')) {
      return 'assets/images/product_meat.jpg';
    }
    if (combined.contains('feed') || combined.contains('grain') || combined.contains('aliment') || combined.contains('mash') || combined.contains('provende')) {
      return 'assets/images/product_feed.jpg';
    }

    return 'assets/images/product_chicken.jpg';
  }

  // List of distinct realistic farm backgrounds
  static final List<String> farmBackgrounds = [
    'assets/images/farm_bg_1.jpg', // Modern climate-controlled barn
    'assets/images/farm_bg_2.jpg', // Free-range pasture run
    'assets/images/farm_bg_3.jpg', // Smart automated facility
    'assets/images/farm_bg_4.jpg', // Golden sunrise eco farm
    'assets/images/farm_bg_5.jpg', // Tropical agrarian poultry paradise
  ];

  static String getFarmBackground(int index, [String? preferredStyle]) {
    if (preferredStyle != null && preferredStyle.isNotEmpty) {
      final match = farmBackgrounds.firstWhere(
        (bg) => bg.contains(preferredStyle.toLowerCase()),
        orElse: () => farmBackgrounds[index % farmBackgrounds.length],
      );
      return match;
    }
    return farmBackgrounds[index % farmBackgrounds.length];
  }
}
