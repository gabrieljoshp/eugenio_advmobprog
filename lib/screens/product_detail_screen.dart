import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final int userId;
  final ValueChanged<Cart>? onCartUpdated;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.userId,
    this.onCartUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                product.thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Image.network(product.thumbnail, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: product.title,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 8.h),
            CustomText(
              text: '\$${product.price.toStringAsFixed(2)}',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 12.h),
            CustomText(
              text: 'Category: ${product.category}',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
            SizedBox(height: 12.h),
            CustomText(
              text: product.description,
              fontSize: 14.sp,
              fontWeight: FontWeight.normal,
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: 'Rating: ${product.rating}',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                CustomText(
                  text: 'Stock: ${product.stock}',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final cart = await CartService().addToCart(
                      userId: userId,
                      productId: product.id,
                      quantity: 1,
                    );

                    if (context.mounted) {
                      onCartUpdated?.call(cart);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added ${product.title} to cart. Total: \$${cart.total.toStringAsFixed(2)}',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add to cart: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFffd41d),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
