import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  final String? token;

  ApiService({this.token});

  // Generic Request Helper
  Future<dynamic> _processResponse(http.Response response) async {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final message = body is Map && body.containsKey('message') 
          ? body['message'] 
          : 'HTTP Error ${response.statusCode}';
      throw Exception(message);
    }
  }

  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: ApiConfig.headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: ApiConfig.headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
        'address': address,
        'avatarUrl': avatarUrl,
      }),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
      headers: ApiConfig.headers(token),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(data),
    );
    return await _processResponse(response);
  }

  // --- Farms ---
  Future<List<dynamic>> getFarms() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/farms'),
      headers: ApiConfig.headers(token),
    );
    final data = await _processResponse(response);
    return data['farms'] ?? [];
  }

  Future<Map<String, dynamic>> createFarm(Map<String, dynamic> farmData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/farms'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(farmData),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> updateFarm(String id, Map<String, dynamic> farmData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/farms/$id'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(farmData),
    );
    return await _processResponse(response);
  }

  Future<void> deleteFarm(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/farms/$id'),
      headers: ApiConfig.headers(token),
    );
    await _processResponse(response);
  }

  // --- IoT Devices ---
  Future<List<dynamic>> getDevices({String? farmId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/devices').replace(
      queryParameters: farmId != null ? {'farmId': farmId} : null,
    );
    final response = await http.get(uri, headers: ApiConfig.headers(token));
    final data = await _processResponse(response);
    return data['devices'] ?? [];
  }

  Future<Map<String, dynamic>> registerDevice(Map<String, dynamic> deviceData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/devices'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(deviceData),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> updateDeviceThresholds(String id, Map<String, dynamic> thresholds) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/devices/$id'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(thresholds),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> toggleAutoMode(String id, bool autoMode) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/devices/$id/mode'),
      headers: ApiConfig.headers(token),
      body: jsonEncode({'autoMode': autoMode}),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> manualOverride(String id, String action) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/devices/$id/override'),
      headers: ApiConfig.headers(token),
      body: jsonEncode({'action': action}),
    );
    return await _processResponse(response);
  }

  // --- Sensors & Automation ---
  Future<Map<String, dynamic>> getLiveReading(String deviceId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sensors/live/$deviceId'),
      headers: ApiConfig.headers(token),
    );
    final data = await _processResponse(response);
    return data['latestReading'] ?? {};
  }

  Future<List<dynamic>> getSensorHistory(String deviceId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sensors/history/$deviceId'),
      headers: ApiConfig.headers(token),
    );
    final data = await _processResponse(response);
    return data['history'] ?? [];
  }

  Future<Map<String, dynamic>> sendTelemetry(Map<String, dynamic> telemetryData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/sensors/telemetry'),
      headers: ApiConfig.headers(),
      body: jsonEncode(telemetryData),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> sendAiAlert(Map<String, dynamic> aiData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/ai/health-alert'),
      headers: ApiConfig.headers(),
      body: jsonEncode(aiData),
    );
    return await _processResponse(response);
  }

  // --- Products ---
  Future<List<dynamic>> getProducts({String? search, String? category, String? farmId}) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (farmId != null && farmId.isNotEmpty) query['farmId'] = farmId;

    final uri = Uri.parse('${ApiConfig.baseUrl}/products').replace(queryParameters: query);
    final response = await http.get(uri, headers: ApiConfig.headers(token));
    final data = await _processResponse(response);
    return data['products'] ?? [];
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/products'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(productData),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/products/$id'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(productData),
    );
    return await _processResponse(response);
  }

  Future<void> deleteProduct(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/products/$id'),
      headers: ApiConfig.headers(token),
    );
    await _processResponse(response);
  }

  // --- Orders ---
  Future<Map<String, dynamic>> createOrder(List<Map<String, dynamic>> items, String shippingAddress) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: ApiConfig.headers(token),
      body: jsonEncode({
        'items': items,
        'shippingAddress': shippingAddress,
      }),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> initiatePayment(String orderId, String paymentMethod) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/pay'),
      headers: ApiConfig.headers(token),
      body: jsonEncode({'paymentMethod': paymentMethod}),
    );
    return await _processResponse(response);
  }

  Future<List<dynamic>> getOrders() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/orders'),
      headers: ApiConfig.headers(token),
    );
    final data = await _processResponse(response);
    return data['orders'] ?? [];
  }

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/status'),
      headers: ApiConfig.headers(token),
      body: jsonEncode({'status': status}),
    );
    return await _processResponse(response);
  }

  // --- Deliveries ---
  Future<List<dynamic>> getDeliveries() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/deliveries'),
      headers: ApiConfig.headers(token),
    );
    final data = await _processResponse(response);
    return data['deliveries'] ?? [];
  }

  Future<Map<String, dynamic>> assignDelivery(String deliveryId, String driverId) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/deliveries/$deliveryId/assign'),
      headers: ApiConfig.headers(token),
      body: jsonEncode({'deliveryPersonId': driverId}),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> updateDeliveryStatus(String deliveryId, String status) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/deliveries/$deliveryId/status'),
      headers: ApiConfig.headers(token),
      body: jsonEncode({'status': status}),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> reportDelayedDelivery(String deliveryId, String delayReason) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/deliveries/$deliveryId/delay'),
      headers: ApiConfig.headers(token),
      body: jsonEncode({'delayReason': delayReason}),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> confirmDelivery(String deliveryId) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/deliveries/$deliveryId/confirm'),
      headers: ApiConfig.headers(token),
    );
    return await _processResponse(response);
  }

  // --- Notifications ---
  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/notifications'),
      headers: ApiConfig.headers(token),
    );
    final data = await _processResponse(response);
    return data['notifications'] ?? [];
  }

  Future<void> markNotificationAsRead(String id) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read'),
      headers: ApiConfig.headers(token),
    );
    await _processResponse(response);
  }

  Future<void> markAllNotificationsAsRead() async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/notifications/read-all'),
      headers: ApiConfig.headers(token),
    );
    await _processResponse(response);
  }

  // --- Admin ---
  Future<Map<String, dynamic>> getAdminStats() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/stats'),
      headers: ApiConfig.headers(token),
    );
    final data = await _processResponse(response);
    return data['stats'] ?? {};
  }

  Future<Map<String, dynamic>> getReports() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/reports'),
      headers: ApiConfig.headers(token),
    );
    final data = await _processResponse(response);
    return data['reports'] ?? {};
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/users'),
      headers: ApiConfig.headers(token),
    );
    final data = await _processResponse(response);
    return data['users'] ?? [];
  }

  Future<List<dynamic>> getFarmers() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/farmers'),
      headers: ApiConfig.headers(token),
    );
    final data = await _processResponse(response);
    return data['farmers'] ?? [];
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(userData),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId'),
      headers: ApiConfig.headers(token),
      body: jsonEncode(userData),
    );
    return await _processResponse(response);
  }

  Future<Map<String, dynamic>> setUserStatus(String userId, String status) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/status'),
      headers: ApiConfig.headers(token),
      body: jsonEncode({'status': status}),
    );
    return await _processResponse(response);
  }

  Future<void> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId'),
      headers: ApiConfig.headers(token),
    );
    await _processResponse(response);
  }
}
