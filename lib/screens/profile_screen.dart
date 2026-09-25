import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/login_type.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'signin_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = UserService();
  late Future<User> _userFuture;
  LoginType _loginType = LoginType.dummyJson;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _userFuture = _loadUser();
  }

  Future<User> _loadUser() async {
    _loginType = await _service.getLoginType();
    return _service.getUserData().then(User.fromJson);
  }

  Future<void> _logout() async {
    await _service.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  Future<void> _updateUsername(User user) async {
    final controller = TextEditingController(text: user.username);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update username'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    if (_loginType == LoginType.firebase) {
      await _service.updateUsername(username: value);
    } else {
      await _service.saveUserData({...user.toJson(), 'username': value.trim()});
    }
    if (mounted) setState(_loadProfile);
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, [current.text, next.text]),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    current.dispose();
    next.dispose();
    if (values == null || values[0].isEmpty || values[1].length < 6) return;
    final user = await _service.getUser();
    await _service.resetPasswordFromCurrentPassword(
      currentPassword: values[0],
      newPassword: values[1],
      email: user.email,
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated.')));
    }
  }

  Future<void> _deleteAccount(User user) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete account?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    if (_loginType == LoginType.firebase) {
      final password = await _passwordDialog();
      if (password == null) return;
      await _service.deleteAccount(email: user.email, password: password);
    } else {
      await _service.logout();
    }
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (_) => false,
      );
    }
  }

  Future<String?> _passwordDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm password'),
        content: TextField(controller: controller, obscureText: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<User>(
    future: _userFuture,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final user = snapshot.data!;
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 26.h, 20.w, 32.h),
          child: Column(
            children: [
              CircleAvatar(
                radius: 43.r,
                backgroundColor: const Color(0xFFFFF2C4),
                backgroundImage: user.image.isNotEmpty
                    ? NetworkImage(user.image)
                    : null,
                child: user.image.isEmpty
                    ? Icon(Icons.person, size: 46.sp, color: nuBLUE)
                    : null,
              ),
              SizedBox(height: 14.h),
              Text(
                user.displayName,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 21.sp,
                ),
              ),
              Text(
                '@${user.username}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: const Color(0xFFC69F14),
                ),
              ),
              SizedBox(height: 22.h),
              _detail(Icons.email_outlined, 'Email', user.email),
              _detail(
                Icons.phone_outlined,
                'Contact',
                user.phone.isEmpty ? 'Not specified' : user.phone,
              ),
              _detail(
                Icons.cake_outlined,
                'Age',
                user.age == 0 ? 'Not specified' : '${user.age}',
              ),
              _detail(
                Icons.login,
                'Login',
                _loginType == LoginType.firebase
                    ? 'Firebase Auth'
                    : 'DummyJSON',
              ),
              SizedBox(height: 14.h),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _updateUsername(user),
                    icon: const Icon(Icons.edit),
                    label: const Text('Username'),
                  ),
                  if (_loginType == LoginType.firebase)
                    OutlinedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Password'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _deleteAccount(user),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6255),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _detail(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, color: nuYELLOW),
    title: Text(label),
    trailing: Text(value, overflow: TextOverflow.ellipsis),
  );
}
