import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import '../widgets/custom_text.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Cart>> _cartFuture;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    _cartFuture = CartService().getCartsByUserId(widget.userId);
  }

  Future<void> _openProduct(CartProduct cartProduct) async {
    try {
      final product = await ProductService().getProductById(cartProduct.id);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(product: product),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load product: $e')));
    }
  }

  Future<void> _updateProductQuantity(
    CartProduct cartProduct, {
    required int delta,
  }) async {
    try {
      final carts = await CartService().getCartsByUserId(widget.userId);
      if (carts.isEmpty) return;

      final cart = carts.first;
      final updatedProducts = cart.products
          .map((product) {
            if (product.id == cartProduct.id) {
              final newQuantity = product.quantity + delta;
              return {
                'id': product.id,
                'quantity': newQuantity <= 0 ? 0 : newQuantity,
              };
            }
            return {'id': product.id, 'quantity': product.quantity};
          })
          .where((product) => (product['quantity'] as int) > 0)
          .toList();

      final updatedCart = await CartService().updateCart(
        cartId: cart.id,
        products: updatedProducts,
        merge: false,
      );

      if (!mounted) return;

      setState(() {
        _cartFuture = Future.value([updatedCart]);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update quantity: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Cart>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: CustomText(
                text: 'Error: ${snapshot.error}',
                fontSize: 14.sp,
              ),
            );
          }

          final carts = snapshot.data ?? [];

          if (carts.isEmpty) {
            return Center(
              child: CustomText(text: 'No cart found', fontSize: 16.sp),
            );
          }

          final cart = carts.first;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadCart();
              });

              await _cartFuture;
            },
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                // CART PRODUCTS
                ...cart.products.map((cartProduct) {
                  return InkWell(
                    onTap: () => _openProduct(cartProduct),
                    borderRadius: BorderRadius.circular(18.r),
                    child: Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.r),
                        child: Row(
                          children: [
                            // PRODUCT IMAGE
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.network(
                                cartProduct.thumbnail,
                                width: 80.w,
                                height: 80.h,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 80.w,
                                  height: 80.h,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.image, size: 26.sp),
                                ),
                              ),
                            ),

                            SizedBox(width: 12.w),

                            // PRODUCT INFORMATION
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: cartProduct.title,
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w600,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  SizedBox(height: 6.h),

                                  CustomText(
                                    text:
                                        '\$${cartProduct.price.toStringAsFixed(2)}',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                  ),

                                  SizedBox(height: 6.h),

                                  Row(
                                    children: [
                                      CustomText(
                                        text:
                                            '${cartProduct.quantity} ${cartProduct.quantity > 1 ? 'items' : 'item'}',
                                        fontSize: 12.sp,
                                      ),

                                      const Spacer(),

                                      Row(
                                        children: [
                                          _quantityButton(
                                            Icons.remove,
                                            () => _updateProductQuantity(
                                              cartProduct,
                                              delta: -1,
                                            ),
                                          ),

                                          SizedBox(width: 8.w),

                                          Container(
                                            width: 34.w,
                                            height: 34.h,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(9.r),
                                            ),
                                            child: CustomText(
                                              text: '${cartProduct.quantity}',
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),

                                          SizedBox(width: 8.w),

                                          _quantityButton(
                                            Icons.add,
                                            () => _updateProductQuantity(
                                              cartProduct,
                                              delta: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                SizedBox(height: 12.h),

                // ORDER SUMMARY
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CustomText(text: 'Subtotal:', fontSize: 16.sp),
                            const Spacer(),
                            CustomText(
                              text: '\$${cart.total.toStringAsFixed(2)}',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ],
                        ),

                        SizedBox(height: 10.h),

                        Row(
                          children: [
                            CustomText(text: 'Delivery:', fontSize: 16.sp),
                            const Spacer(),
                            CustomText(text: '\$0.00', fontSize: 16.sp),
                          ],
                        ),

                        SizedBox(height: 12.h),

                        Divider(color: Theme.of(context).dividerColor),

                        SizedBox(height: 12.h),

                        Row(
                          children: [
                            CustomText(
                              text: 'Total:',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            const Spacer(),
                            CustomText(
                              text: '\$${cart.total.toStringAsFixed(2)}',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                // CONFIRM ORDER BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD41D),
                      foregroundColor: const Color(0xFF1F2A5A),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: CustomText(
                      text: 'Confirm Order',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2A5A),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 30.w,
        height: 30.h,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD41D),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: const Color(0xFF1F2A5A), size: 18.sp),
      ),
    );
  }
}
