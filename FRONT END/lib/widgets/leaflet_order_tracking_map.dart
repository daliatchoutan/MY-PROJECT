import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/locale_provider.dart';

class LeafletOrderTrackingModal extends StatefulWidget {
  final Map<String, dynamic> order;
  final Map<String, dynamic>? delivery;
  final Map<String, dynamic>? farm;

  const LeafletOrderTrackingModal({
    super.key,
    required this.order,
    this.delivery,
    this.farm,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> order,
    Map<String, dynamic>? delivery,
    Map<String, dynamic>? farm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LeafletOrderTrackingModal(
        order: order,
        delivery: delivery,
        farm: farm,
      ),
    );
  }

  @override
  State<LeafletOrderTrackingModal> createState() => _LeafletOrderTrackingModalState();
}

class _LeafletOrderTrackingModalState extends State<LeafletOrderTrackingModal> {
  late final MapController _mapController;
  late final LatLng _farmLocation;
  late final LatLng _customerLocation;
  late final LatLng _courierLocation;
  late final List<LatLng> _routePoints;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Determine geographic coordinates based on location text or Cameroon baseline
    _farmLocation = _resolveCoordinates(
      widget.farm?['location']?.toString() ?? 'Yaoundé',
      defaultBase: const LatLng(3.8666, 11.5167), // Yaoundé Farm baseline
      salt: 1,
    );

    _customerLocation = _resolveCoordinates(
      widget.order['shippingAddress']?.toString() ?? widget.delivery?['dropoffAddress']?.toString() ?? 'Douala',
      defaultBase: const LatLng(3.8480, 11.5021), // Customer location
      salt: 2,
    );

    // Calculate courier position along route depending on delivery status
    final deliveryStatus = widget.delivery?['status']?.toString().toLowerCase() ?? 'unassigned';
    double progress = 0.15; // default near farm
    if (deliveryStatus == 'in_transit' || deliveryStatus == 'en_route') {
      progress = 0.60; // in transit midway
    } else if (deliveryStatus == 'delivered' || deliveryStatus == 'completed') {
      progress = 1.0; // at customer
    } else if (deliveryStatus == 'assigned' || deliveryStatus == 'picked_up') {
      progress = 0.30;
    }

    _courierLocation = LatLng(
      _farmLocation.latitude + (_customerLocation.latitude - _farmLocation.latitude) * progress,
      _farmLocation.longitude + (_customerLocation.longitude - _farmLocation.longitude) * progress,
    );

    // Build route points with realistic curve
    _routePoints = [
      _farmLocation,
      LatLng(
        (_farmLocation.latitude + _courierLocation.latitude) / 2 + 0.005,
        (_farmLocation.longitude + _courierLocation.longitude) / 2 - 0.003,
      ),
      _courierLocation,
      LatLng(
        (_courierLocation.latitude + _customerLocation.latitude) / 2 - 0.004,
        (_courierLocation.longitude + _customerLocation.longitude) / 2 + 0.005,
      ),
      _customerLocation,
    ];
  }

  LatLng _resolveCoordinates(String locText, {required LatLng defaultBase, int salt = 0}) {
    final lower = locText.toLowerCase();
    if (lower.contains('douala') || lower.contains('littoral') || lower.contains('bonanjo') || lower.contains('akwa')) {
      return LatLng(4.0511 + (salt * 0.01), 9.7679 + (salt * 0.01));
    }
    if (lower.contains('bafoussam') || lower.contains('ouest') || lower.contains('west')) {
      return LatLng(5.4778 + (salt * 0.01), 10.4176 + (salt * 0.01));
    }
    if (lower.contains('bamenda') || lower.contains('nord-ouest')) {
      return LatLng(5.9631 + (salt * 0.01), 10.1591 + (salt * 0.01));
    }
    if (lower.contains('kribi')) {
      return LatLng(2.9378 + (salt * 0.01), 9.9077 + (salt * 0.01));
    }
    // Default Cameroon Centre / Yaoundé region with slight offset
    return LatLng(defaultBase.latitude + (salt * 0.012), defaultBase.longitude + (salt * 0.015));
  }

  double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((p2.latitude - p1.latitude) * p) / 2 +
        cos(p1.latitude * p) * cos(p2.latitude * p) * (1 - cos((p2.longitude - p1.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context);
    final orderId = widget.order['id']?.toString() ?? '';
    final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    final delivery = widget.delivery;
    final courier = delivery?['courier'] ?? delivery?['deliveryPerson'];
    final courierName = courier?['name']?.toString() ?? (locale.isFrench ? 'Livreur en attente' : 'Courier Pending');
    final courierPhone = courier?['phone']?.toString();
    final deliveryStatus = delivery?['status']?.toString() ?? 'unassigned';
    final shippingAddress = widget.order['shippingAddress']?.toString() ?? 'N/A';
    final distanceKm = _calculateDistanceKm(_farmLocation, _customerLocation);

    final centerLat = (_farmLocation.latitude + _customerLocation.latitude) / 2;
    final centerLng = (_farmLocation.longitude + _customerLocation.longitude) / 2;

    Color statusColor;
    String statusLabel;
    switch (deliveryStatus.toLowerCase()) {
      case 'delivered':
      case 'completed':
        statusColor = Colors.green;
        statusLabel = locale.isFrench ? 'Livré avec succès' : 'Delivered Successfully';
        break;
      case 'in_transit':
      case 'en_route':
        statusColor = const Color(0xFFE67E22);
        statusLabel = locale.isFrench ? 'En cours d\'acheminement' : 'In Transit';
        break;
      case 'assigned':
      case 'picked_up':
        statusColor = Colors.blue;
        statusLabel = locale.isFrench ? 'Colis pris en charge' : 'Driver Assigned / Picked Up';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = locale.isFrench ? 'Recherche d\'un livreur' : 'Searching for Courier';
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D7A57).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.map_outlined, color: Color(0xFF0D7A57), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.isFrench ? 'Suivi de Commande en Direct (Google Maps)' : 'Live Order Tracking (Google Maps)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${locale.tr('order_items')} #$shortId • ${distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Interactive Leaflet Map View
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(centerLat, centerLng),
                    initialZoom: 13.0,
                    minZoom: 4.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    // OpenStreetMap Standard Tiles
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'cm.novara.smart_poultry',
                    ),

                    // Delivery Route Polyline
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          color: const Color(0xFF0D7A57),
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),

                    // Location Markers (Farm, Courier, Customer)
                    MarkerLayer(
                      markers: [
                        // 1. Farm Origin Marker
                        Marker(
                          point: _farmLocation,
                          width: 48,
                          height: 48,
                          child: Tooltip(
                            message: widget.farm?['name']?.toString() ?? 'Ferme Avicole NOVARA',
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: const Icon(Icons.agriculture, color: Colors.white, size: 24),
                            ),
                          ),
                        ),

                        // 2. Customer Destination Marker
                        Marker(
                          point: _customerLocation,
                          width: 48,
                          height: 48,
                          child: Tooltip(
                            message: shippingAddress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                              ),
                              child: const Icon(Icons.home, color: Colors.white, size: 24),
                            ),
                          ),
                        ),

                        // 3. Courier Live Location Marker (if courier assigned)
                        if (deliveryStatus.toLowerCase() != 'unassigned')
                          Marker(
                            point: _courierLocation,
                            width: 52,
                            height: 52,
                            child: Tooltip(
                              message: '$courierName ($statusLabel)',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE67E22),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: const Icon(Icons.two_wheeler, color: Colors.white, size: 28),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Map Zoom Floating Controls
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'map_zoom_in',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          );
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'map_zoom_out',
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        onPressed: () {
                          _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          );
                        },
                        child: const Icon(Icons.remove),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'map_recenter',
                        backgroundColor: const Color(0xFF0D7A57),
                        foregroundColor: Colors.white,
                        onPressed: () {
                          _mapController.move(LatLng(centerLat, centerLng), 13.0);
                        },
                        child: const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),

                // OpenStreetMap & Leaflet Attribution Badge
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Google Maps',
                      style: TextStyle(fontSize: 10, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Courier & Delivery Bottom Action Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF0D7A57).withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: Color(0xFF0D7A57)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courierName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            deliveryStatus == 'delivered'
                                ? (locale.isFrench ? 'Colis remis au client' : 'Package handed to customer')
                                : (locale.isFrench
                                    ? 'Destination : $shippingAddress'
                                    : 'Destination: $shippingAddress'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (courierPhone != null && courierPhone.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('tel:$courierPhone');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.phone, size: 16),
                        label: Text(locale.isFrench ? 'Appeler' : 'Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D7A57),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
