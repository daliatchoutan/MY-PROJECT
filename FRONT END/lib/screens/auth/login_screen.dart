import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/language_switcher.dart';
import 'register_screen.dart';
import '../dashboards/farmer_dashboard.dart';
import '../dashboards/customer_dashboard.dart';
import '../dashboards/delivery_dashboard.dart';
import '../dashboards/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = true;

  String? _savedEmail;
  String? _savedPassword;
  String? _savedName;
  String? _savedRole;

  @override
  void initState() {
    super.initState();
    _loadSavedAccount();
  }

  Future<void> _loadSavedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_login_email');
    final password = prefs.getString('saved_login_password');
    final name = prefs.getString('saved_login_name');
    final role = prefs.getString('saved_login_role');

    if (mounted && email != null && email.isNotEmpty) {
      setState(() {
        _savedEmail = email;
        _savedPassword = password;
        _savedName = name;
        _savedRole = role;
        _emailController.text = email;
        if (password != null) {
          _passwordController.text = password;
        }
      });
    }
  }

  Future<void> _persistAccountDetails(String email, String password, dynamic user) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_login_email', email);
      await prefs.setString('saved_login_password', password);
      if (user != null) {
        await prefs.setString('saved_login_name', user['name'] ?? '');
        await prefs.setString('saved_login_role', user['role'] ?? '');
      }
    } else {
      await prefs.remove('saved_login_email');
      await prefs.remove('saved_login_password');
      await prefs.remove('saved_login_name');
      await prefs.remove('saved_login_role');
    }
  }

  void _navigateToDashboard(String role) {
    Widget targetScreen;
    switch (role) {
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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  void _quickLogin(String email, String password) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await auth.login(email.trim(), password);

    if (!mounted) return;

    if (success) {
      await _persistAccountDetails(email.trim(), password, auth.user);
      _navigateToDashboard(auth.role);
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await auth.login(email, password);

    if (!mounted) return;

    if (success) {
      await _persistAccountDetails(email, password, auth.user);
      _navigateToDashboard(auth.role);
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
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
        title: Text(locale.tr('sign_in')),
        actions: const [
          LanguageSwitcher(isLight: true),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/images/novara_logo.jpg', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'NOVARA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D7A57),
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale.tr('app_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Quick One-Tap Account Recovery Card
                  if (_savedEmail != null && _savedPassword != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0D7A57).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFF0D7A57),
                                child: Text(
                                  (_savedName != null && _savedName!.isNotEmpty ? _savedName![0] : 'U').toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _savedName ?? 'Saved User',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      _savedEmail!,
                                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                                    ),
                                    if (_savedRole != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 3),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE67E22),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _savedRole!,
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: auth.isLoading ? null : () => _quickLogin(_savedEmail!, _savedPassword!),
                              icon: const Icon(Icons.bolt, size: 18),
                              label: Text(
                                '${locale.tr('continue_as')} ${_savedName ?? _savedEmail}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D7A57),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: locale.tr('email_address'),
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val != null && val.contains('@') ? null : 'Enter a valid email',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: locale.tr('password'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (val) =>
                        val != null && val.length >= 6 ? null : 'Password must be 6+ chars',
                  ),
                  const SizedBox(height: 10),
                  // Remember Me Switch/Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: const Color(0xFF0D7A57),
                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                      ),
                      Expanded(
                        child: Text(
                          locale.tr('remember_me'),
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color(0xFF0D7A57),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            locale.tr('sign_in'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(locale.isFrench ? "Pas encore de compte ? " : "Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: Text(
                          locale.tr('create_account'),
                          style: const TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
