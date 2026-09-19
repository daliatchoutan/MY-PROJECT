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
    String? resolvedUrl = imageUrl;
    final nameLower = (product != null ? product['name'] ?? '' : '').toString().toLowerCase();
    final descLower = (product != null ? product['description'] ?? '' : '').toString().toLowerCase();
    final isBrown = nameLower.contains('brown') || nameLower.contains('brun') || descLower.contains('brown') || descLower.contains('brun');

    if (isBrown && (resolvedUrl == null || resolvedUrl.contains('product_eggs.jpg'))) {
      resolvedUrl = '/uploads/products/product_brown_eggs.jpg';
    }

    final fallbackAsset = getProductImage(product);

    if (resolvedUrl != null && resolvedUrl.trim().isNotEmpty) {
      final fullUrl = ApiConfig.getImageUrl(resolvedUrl);
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

    // 1. Strict Category Matching First
    if (cat.contains('egg') || cat.contains('oeuf')) {
      if (name.contains('brown') || name.contains('brun') || desc.contains('brown') || desc.contains('brun')) {
        return 'assets/images/product_brown_eggs.jpg';
      }
      return 'assets/images/product_eggs.jpg';
    }

    if (cat.contains('feed') || cat.contains('aliment') || cat.contains('provende') || cat.contains('grain') || cat.contains('mash')) {
      return 'assets/images/product_feed.jpg';
    }

    if (cat.contains('meat') || cat.contains('viande')) {
      if (name.contains('whole') || name.contains('entier') || name.contains('poulet frais') || name.contains('dressed') || name.contains('fresh chicken')) {
        return 'assets/images/product_fresh_chicken.jpg';
      }
      return 'assets/images/product_meat.jpg';
    }

    // 2. Keyword-Based Name & Description Matching
    if (name.contains('egg') || name.contains('oeuf') || name.contains('tray') || desc.contains('table eggs') || desc.contains('laying eggs')) {
      if (name.contains('brown') || name.contains('brun') || desc.contains('brown') || desc.contains('brun')) {
        return 'assets/images/product_brown_eggs.jpg';
      }
      return 'assets/images/product_eggs.jpg';
    }

    if (name.contains('feed') || name.contains('mash') || name.contains('provende') || name.contains('aliment') || name.contains('pellet')) {
      return 'assets/images/product_feed.jpg';
    }

    if (name.contains('fillet') || name.contains('breast') || name.contains('drumstick') || name.contains('thigh') || name.contains('cut') || name.contains('morceau') || (name.contains('meat') && !name.contains('live'))) {
      return 'assets/images/product_meat.jpg';
    }

    if (name.contains('whole chicken') || name.contains('dressed') || name.contains('poulet frais') || (name.contains('fresh') && name.contains('chicken') && !name.contains('live') && !cat.contains('live'))) {
      return 'assets/images/product_fresh_chicken.jpg';
    }

    // 3. Live Poultry Subtypes
    final combined = '$name $cat $desc';
    if (combined.contains('chick') || combined.contains('day-old') || combined.contains('poussin')) {
      return 'assets/images/product_chicks.jpg';
    }
    if (combined.contains('rooster') || combined.contains('coq') || combined.contains('cockerel')) {
      return 'assets/images/product_rooster.jpg';
    }
    if (combined.contains('layer') || combined.contains('pondeuse')) {
      return 'assets/images/product_layer.jpg';
    }
    if (combined.contains('broiler') || combined.contains('chair')) {
      return 'assets/images/product_broiler.jpg';
    }

    return 'assets/images/product_chicken.jpg';
  }

  // Returns image asset path corresponding to each category tab
  static String getCategoryThumbnail(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('egg') || cat.contains('oeuf')) {
      return 'assets/images/product_eggs.jpg';
    }
    if (cat.contains('meat') || cat.contains('viande')) {
      return 'assets/images/product_meat.jpg';
    }
    if (cat.contains('feed') || cat.contains('aliment') || cat.contains('provende')) {
      return 'assets/images/product_feed.jpg';
    }
    if (cat.contains('live') || cat.contains('vivant') || cat.contains('poultry') || cat.contains('volaille')) {
      return 'assets/images/product_broiler.jpg';
    }
    return 'assets/images/novara_logo.jpg';
  }

  // Flexible category matching across UI filters and backend data
  static bool matchesCategory(String? productCategory, String filter) {
    if (filter == 'All') return true;
    if (productCategory == null || productCategory.trim().isEmpty) return false;
    final cat = productCategory.toLowerCase();
    final f = filter.toLowerCase();

    if (f.contains('egg')) return cat.contains('egg') || cat.contains('oeuf');
    if (f.contains('meat')) return cat.contains('meat') || cat.contains('viande');
    if (f.contains('feed')) return cat.contains('feed') || cat.contains('aliment') || cat.contains('provende');
    if (f.contains('live')) return cat.contains('live') || cat.contains('vivant') || cat.contains('poultry') || cat.contains('volaille');

    return cat.contains(f);
  }

  // List of distinct realistic farm backgrounds
  static final List<String> farmBackgrounds = [
    'assets/images/farm_background.jpg', // Novara smart eco-poultry solution
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
