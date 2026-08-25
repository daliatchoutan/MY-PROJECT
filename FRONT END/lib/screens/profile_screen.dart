import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _avatarController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameController.text = user['name'] ?? '';
      _phoneController.text = user['phone'] ?? '';
      _addressController.text = user['address'] ?? '';
      _avatarController.text = user['avatarUrl'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.updateProfile({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'avatarUrl': _avatarController.text.trim(),
    });

    if (!mounted) return;

    if (success) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Failed to update profile'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user ?? {};
    final avatarUrl = user['avatarUrl'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Avatar Display
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.green.shade100,
                    backgroundImage: (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                        ? Text(
                            (user['name'] ?? 'U')[0].toUpperCase(),
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user['name'] ?? 'User Profile',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text(user['role'] ?? 'User'),
                  backgroundColor: Colors.green.shade50,
                  side: BorderSide(color: Colors.green.shade300),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text((user['status'] ?? 'active').toUpperCase()),
                  backgroundColor: Colors.blue.shade50,
                  side: BorderSide(color: Colors.blue.shade300),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isEditing) ...[
              TextFormField(
                controller: _avatarController,
                decoration: const InputDecoration(
                  labelText: 'Profile Picture Image URL',
                  prefixIcon: Icon(Icons.image_outlined),
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com/my-photo.jpg',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address / Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: auth.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Profile Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email Address'),
                      subtitle: Text(user['email'] ?? 'N/A'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Phone Number'),
                      subtitle: Text(user['phone'] ?? 'Not set'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Address / Location'),
                      subtitle: Text(user['address'] ?? 'Not set'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
