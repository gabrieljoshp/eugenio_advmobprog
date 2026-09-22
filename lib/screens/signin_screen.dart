import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() { _usernameController.dispose(); _passwordController.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final response = await _userService.loginUser(_usernameController.text.trim(), _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen(user: User.fromJson(response))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to sign in. Check your username and password.')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFAFF),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Form(key: _formKey, child: Column(children: [
        Image.asset('assets/images/nubdexchange_logo.png', width: 62.w),
        SizedBox(height: 12.h),
        Text('Welcome', style: TextStyle(fontFamily: 'Poppins', fontSize: 28.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 42.h),
        _field(controller: _usernameController, label: 'Username', icon: Icons.person_outline, validator: (value) => value == null || value.trim().isEmpty ? 'Enter your username' : null),
        SizedBox(height: 16.h),
        _field(controller: _passwordController, label: 'Password', icon: Icons.lock_outline, obscureText: _obscurePassword, validator: (value) => value == null || value.isEmpty ? 'Enter your password' : null, suffix: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
        SizedBox(height: 20.h),
        SizedBox(width: double.infinity, height: 54.h, child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(backgroundColor: nuBLUE, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13.r))),
          child: _isLoading ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Log In', style: TextStyle(fontFamily: 'Poppins', fontSize: 16.sp)),
        )),
        SizedBox(height: 20.h),
        Text('Demo account: emilys / emilyspass', style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp, color: Colors.black54)),
      ])),
    ))),
  );

  Widget _field({required TextEditingController controller, required String label, required IconData icon, required String? Function(String?) validator, bool obscureText = false, Widget? suffix}) => TextFormField(
    controller: controller, validator: validator, obscureText: obscureText, style: const TextStyle(fontFamily: 'Poppins'),
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: nuBLUE), suffixIcon: suffix, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13.r)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13.r), borderSide: const BorderSide(color: Color(0xFF77727A))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13.r), borderSide: const BorderSide(color: nuBLUE, width: 2))),
  );
}
