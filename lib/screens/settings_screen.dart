import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: themeProvider.isDark ? 'Appearance' : 'Appearance',
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: themeProvider.isDark ? Colors.white : Colors.black,
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: themeProvider.isDark ? 'Light mode' : 'Dark mode',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.isDark ? Colors.white : Colors.black,
                  ),
                  Switch(
                    value: themeProvider.isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
