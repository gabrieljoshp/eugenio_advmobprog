import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import 'signin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final isLoggedIn = await _userService.isLoggedIn();
    if (!mounted) return;
    final nextScreen = isLoggedIn
        ? HomeScreen(user: await _userService.getUser())
        : const SignInScreen();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFAFF),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/nubdexchange_logo.png', width: 132.w),
          SizedBox(height: 20.h),
          Text(
            'NUBD Exchange',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1D24),
            ),
          ),
          SizedBox(height: 28.h),
          SizedBox(
            height: 24.r,
            width: 24.r,
            child: const CircularProgressIndicator(
              color: nuYELLOW,
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    ),
  );
}
