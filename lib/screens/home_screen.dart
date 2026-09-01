import 'package:eugenio_advmobprog/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'product_screen.dart';
import 'cart_screen.dart';

import '../widgets/custom_text.dart';
import '../screens/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final int userId;

  const HomeScreen({super.key, this.username = '', required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: nuBLUE,
          automaticallyImplyLeading: false,
          elevation: 2,
          title: (_selectedIndex == 0)
              ? Image.asset('assets/images/nubdexchange_logo.png', scale: 10.sp)
              : CustomText(
                  text: (_selectedIndex == 1)
                      ? 'Cart'
                      : (_selectedIndex == 2)
                      ? 'Profile'
                      : 'Home',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, color: Colors.white, size: 24.sp),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: [
            const ProductScreen(),
            CartScreen(userId: widget.userId),
          ],
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),
        floatingActionButton: _selectedIndex == 1
            ? null
            : Padding(
                padding: EdgeInsets.only(bottom: 60.h),
                child: FloatingActionButton(
                  backgroundColor: nuYELLOW,
                  foregroundColor: nuBLUE,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatScreen(),
                      ),
                    );
                  },
                  child: const Icon(Icons.chat_bubble_outline),
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });

    _pageController.jumpToPage(value);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
