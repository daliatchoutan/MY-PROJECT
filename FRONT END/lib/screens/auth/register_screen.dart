import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/language_switcher.dart';
import '../dashboards/farmer_dashboard.dart';
import '../dashboards/customer_dashboard.dart';
import '../dashboards/delivery_dashboard.dart';
import '../dashboards/admin_dashboard.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cniController = TextEditingController();
  final _addressController = TextEditingController();
  final _avatarController = TextEditingController();

  // Farmer specific
  final _professionalLicenseController = TextEditingController();

  // Delivery Person specific
  final _driverLicenseController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  String _selectedVehicleType = 'Motorcycle';

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _selectedRole = 'Customer';

  final List<String> _roles = ['Customer', 'Farmer', 'Delivery Person'];
  final List<String> _vehicleTypes = ['Motorcycle', 'Car', 'Van', 'Bicycle', 'Walking / On Foot'];

  @override
  void initState() {
    super.initState();
    _tryAutoRecover();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _cniController.dispose();
    _addressController.dispose();
    _avatarController.dispose();
    _professionalLicenseController.dispose();
    _driverLicenseController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  Future<void> _tryAutoRecover() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted && prefs.containsKey('saved_reg_name')) {
      setState(() {
        _nameController.text = prefs.getString('saved_reg_name') ?? '';
        _emailController.text = prefs.getString('saved_reg_email') ?? '';
        _phoneController.text = prefs.getString('saved_reg_phone') ?? '';
        _cniController.text = prefs.getString('saved_reg_cni') ?? '';
        _addressController.text = prefs.getString('saved_reg_address') ?? '';
        final role = prefs.getString('saved_reg_role');
        if (role != null && _roles.contains(role)) {
          _selectedRole = role;
        }
      });
    }
  }

  Future<void> _recoverInformation() async {
    final locale = Provider.of<LocaleProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    if (!prefs.containsKey('saved_reg_name') && !prefs.containsKey('saved_reg_email')) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(locale.tr('no_saved_info')), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _nameController.text = prefs.getString('saved_reg_name') ?? _nameController.text;
      _emailController.text = prefs.getString('saved_reg_email') ?? _emailController.text;
      _phoneController.text = prefs.getString('saved_reg_phone') ?? _phoneController.text;
      _cniController.text = prefs.getString('saved_reg_cni') ?? _cniController.text;
      _addressController.text = prefs.getString('saved_reg_address') ?? _addressController.text;
      final role = prefs.getString('saved_reg_role');
      if (role != null && _roles.contains(role)) {
        _selectedRole = role;
      }
    });

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(locale.tr('info_recovered')), backgroundColor: const Color(0xFF0D7A57)),
    );
  }

  Future<void> _saveInformationForRecovery() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_reg_name', _nameController.text.trim());
    await prefs.setString('saved_reg_email', _emailController.text.trim());
    await prefs.setString('saved_reg_phone', _phoneController.text.trim());
    await prefs.setString('saved_reg_cni', _cniController.text.trim());
    await prefs.setString('saved_reg_address', _addressController.text.trim());
    await prefs.setString('saved_reg_role', _selectedRole);

    // Also save for One-Tap login recovery
    await prefs.setString('saved_login_email', _emailController.text.trim());
    await prefs.setString('saved_login_password', _passwordController.text);
    await prefs.setString('saved_login_name', _nameController.text.trim());
    await prefs.setString('saved_login_role', _selectedRole);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Save info locally so user can recover it anytime
    await _saveInformationForRecovery();

    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      role: _selectedRole,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      cniNumber: _cniController.text.trim().isNotEmpty ? _cniController.text.trim() : null,
      professionalLicenseNumber: _selectedRole == 'Farmer' && _professionalLicenseController.text.trim().isNotEmpty
          ? _professionalLicenseController.text.trim()
          : null,
      driverLicenseNumber: _selectedRole == 'Delivery Person' && _driverLicenseController.text.trim().isNotEmpty
          ? _driverLicenseController.text.trim()
          : null,
      vehicleType: _selectedRole == 'Delivery Person' ? _selectedVehicleType : null,
      vehiclePlateNumber: _selectedRole == 'Delivery Person' && _vehiclePlateController.text.trim().isNotEmpty
          ? _vehiclePlateController.text.trim()
          : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      avatarUrl: _avatarController.text.trim().isNotEmpty ? _avatarController.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      Widget targetScreen;
      switch (auth.role) {
        case 'Farmer':
          targetScreen = const FarmerDashboard();
          break;
        case 'Customer':
          targetScreen = const CustomerDashboard();
          break;
        case 'Delivery Person':
          targetScreen = const DeliveryDashboard();
          break;
        case 'Administrator':
          targetScreen = const AdminDashboard();
          break;
        default:
          targetScreen = const CustomerDashboard();
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => targetScreen),
        (route) => false,
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final locale = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.tr('create_account')),
        actions: const [
          LanguageSwitcher(isLight: true),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/novara_logo.jpg', fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  locale.tr('join_novara'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D7A57),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  locale.tr('select_role_desc'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                // Quick Recover Info Button
                OutlinedButton.icon(
                  onPressed: _recoverInformation,
                  icon: const Icon(Icons.history_toggle_off, size: 18, color: Color(0xFFE67E22)),
                  label: Text(
                    locale.tr('recover_info'),
                    style: const TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE67E22)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: locale.tr('user_role'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role == 'Customer' ? '${locale.tr('role_customer')} (Default)' : role),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 14),

                // Role-specific Information Banner
                if (_selectedRole == 'Farmer') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Farmer accounts have immediate active access. You can add one or multiple poultry farms directly from your dashboard after registration.',
                            style: TextStyle(color: Color(0xFF1B5E20), fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ] else if (_selectedRole == 'Delivery Person') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFB74D)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.two_wheeler, color: Color(0xFFE65100)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Delivery accounts receive instant access to delivery jobs. Profile picture is completely optional.',
                            style: TextStyle(color: Color(0xFFBF360C), fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Universal Required Fields
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: locale.tr('full_name'),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) => val != null && val.trim().isNotEmpty ? null : 'Full name is required',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: locale.tr('email_address'),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email is required';
                    if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _selectedRole == 'Customer'
                        ? '${locale.tr('phone_number')} (Optional)'
                        : '${locale.tr('phone_number')} *',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (_selectedRole != 'Customer' && (val == null || val.trim().isEmpty)) {
                      return 'Phone number is required for ${_selectedRole}s';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cniController,
                  decoration: InputDecoration(
                    labelText: _selectedRole == 'Customer'
                        ? 'CNI / National ID Card Number (Optional)'
                        : 'CNI / National ID Card Number *',
                    hintText: 'e.g. 1029384756',
                    prefixIcon: const Icon(Icons.credit_card_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (_selectedRole != 'Customer' && (val == null || val.trim().isEmpty)) {
                      return 'CNI / National ID Card Number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: locale.tr('password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (val) => val != null && val.length >= 6 ? null : 'Min 6 characters required',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please confirm your password';
                    if (val != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // FARMER SPECIFIC FIELDS
                if (_selectedRole == 'Farmer') ...[
                  TextFormField(
                    controller: _professionalLicenseController,
                    decoration: const InputDecoration(
                      labelText: 'Professional License Number (Optional)',
                      hintText: 'e.g. AGR-2026-9921',
                      prefixIcon: Icon(Icons.verified_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // DELIVERY PERSON SPECIFIC FIELDS
                if (_selectedRole == 'Delivery Person') ...[
                  TextFormField(
                    controller: _avatarController,
                    decoration: const InputDecoration(
                      labelText: 'Profile Picture URL (100% Optional)',
                      hintText: 'https://... or leave empty',
                      helperText: 'Optional - accept null or empty without any error',
                      prefixIcon: Icon(Icons.image_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _driverLicenseController,
                    decoration: const InputDecoration(
                      labelText: "Driver's License Number (Optional)",
                      hintText: 'e.g. DL-987654321',
                      prefixIcon: Icon(Icons.drive_eta_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVehicleType,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Type',
                      prefixIcon: Icon(Icons.commute_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: _vehicleTypes.map((vt) {
                      return DropdownMenuItem(value: vt, child: Text(vt));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedVehicleType = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_selectedVehicleType != 'Walking / On Foot') ...[
                    TextFormField(
                      controller: _vehiclePlateController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle License Plate Number (Optional)',
                        hintText: 'e.g. LT 5432 AB',
                        prefixIcon: Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ],

                // CUSTOMER SPECIFIC FIELDS
                if (_selectedRole == 'Customer') ...[
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: locale.tr('delivery_address'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7A57),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : Text(locale.tr('create_account'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    locale.tr('already_account'),
                    style: const TextStyle(color: Color(0xFF0D7A57), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
