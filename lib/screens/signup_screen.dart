import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _age = TextEditingController();
  final _contact = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _service = UserService();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _age,
      _contact,
      _username,
      _email,
      _password,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _signup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final credential = await _service.createAccount(
        email: _email.text.trim(),
        password: _password.text,
        username: _username.text.trim(),
      );
      final user = credential.user;
      if (user != null) {
        final token = await user.getIdToken() ?? '';
        await _service.saveUserData({
          'id': user.uid.hashCode,
          'username': _username.text.trim(),
          'email': _email.text.trim(),
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'age': int.parse(_age.text),
          'phone': _contact.text.trim(),
          'accessToken': token,
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. You can now sign in with Firebase.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to create account: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create account')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(24.w),
          children: [
            _field(_firstName, 'First name', Icons.person_outline),
            _field(_lastName, 'Last name', Icons.person_outline),
            _field(
              _age,
              'Age',
              Icons.cake_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                final age = int.tryParse(value ?? '');
                return age == null || age < 13
                    ? 'Enter a valid age (13+)'
                    : null;
              },
            ),
            _field(
              _contact,
              'Contact number',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _field(
              _username,
              'Username',
              Icons.alternate_email,
              validator: (value) => value == null || value.trim().length < 3
                  ? 'Use at least 3 characters'
                  : null,
            ),
            _field(
              _email,
              'Email address',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter a valid email'
                  : null,
            ),
            _field(
              _password,
              'Password',
              Icons.lock_outline,
              obscureText: _obscure,
              validator: (value) => value == null || value.length < 6
                  ? 'Use at least 6 characters'
                  : null,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 54.h,
              child: ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: nuBLUE,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign up'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffix,
  }) => Padding(
    padding: EdgeInsets.only(bottom: 14.h),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator:
          validator ??
          (value) =>
              value == null || value.trim().isEmpty ? 'Enter $label' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: nuBLUE),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13.r)),
      ),
    ),
  );
}
