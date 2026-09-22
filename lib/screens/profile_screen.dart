import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'signin_screen.dart';

class ProfileScreen extends StatelessWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    await UserService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SignInScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(20.w, 26.h, 20.w, 32.h),
    child: Column(children: [
      Container(width: double.infinity, padding: EdgeInsets.symmetric(vertical: 27.h, horizontal: 20.w), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 18, offset: const Offset(0, 7))]), child: Column(children: [
        CircleAvatar(radius: 43.r, backgroundColor: const Color(0xFFFFF2C4), backgroundImage: user.image.isNotEmpty ? NetworkImage(user.image) : null, child: user.image.isEmpty ? Icon(Icons.person, size: 46.sp, color: nuBLUE) : null),
        SizedBox(height: 14.h),
        Text(user.displayName, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 21.sp)),
        SizedBox(height: 2.h),
        Text('@${user.username}', style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp, color: const Color(0xFFC69F14))),
      ])),
      SizedBox(height: 22.h),
      Container(padding: EdgeInsets.symmetric(horizontal: 16.w), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 15, offset: const Offset(0, 6))]), child: Column(children: [
        _detail(Icons.email_outlined, 'Email', user.email), const Divider(height: 1),
        _detail(Icons.wc_outlined, 'Gender', user.gender.isEmpty ? 'Not specified' : user.gender), const Divider(height: 1),
        _detail(Icons.badge_outlined, 'User ID', '#${user.id}'),
      ])),
      SizedBox(height: 32.h),
      SizedBox(width: double.infinity, height: 56.h, child: ElevatedButton.icon(onPressed: () => _logout(context), icon: const Icon(Icons.logout), label: Text('Log Out', style: TextStyle(fontFamily: 'Poppins', fontSize: 16.sp)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6255), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r))))),
    ]),
  ));

  Widget _detail(IconData icon, String label, String value) => Padding(padding: EdgeInsets.symmetric(vertical: 16.h), child: Row(children: [
    Icon(icon, color: nuYELLOW, size: 23.sp), SizedBox(width: 15.w),
    Text(label, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14.sp)), const Spacer(),
    Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: TextStyle(fontFamily: 'Poppins', color: Colors.black54, fontSize: 13.sp))),
  ]));
}
