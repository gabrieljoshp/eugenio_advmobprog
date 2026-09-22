import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'product_detail_screen.dart';

// models
import '../models/product.dart';
import '../models/cart.dart';
// services
import '../services/product_service.dart';

// widgets
import '../widgets/custom_text.dart';

class ProductScreen extends StatefulWidget {
  final int userId;
  final ValueChanged<Cart>? onCartUpdated;

  const ProductScreen({
    super.key,
    required this.userId,
    this.onCartUpdated,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final Future<List<Product>> _productsFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService().getAllProducts();
  }

  List<Product> _filterProducts(List<Product> products) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return products;
    }

    return products.where((product) {
      final title = product.title.toLowerCase();
      final category = product.category.toLowerCase();
      return title.contains(query) || category.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: ScreenUtil().screenWidth,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search products',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: const CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: CustomText(
                      text: 'Error: ${snapshot.error}',
                      fontSize: 14.sp,
                    ),
                  );
                }

                final products = _filterProducts(snapshot.data ?? []);
                if (products.isEmpty) {
                  return Center(
                    child: CustomText(
                      text: 'No products found',
                      fontSize: 14.sp,
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.w,
                    mainAxisSpacing: 10.h,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              product: product,
                              userId: widget.userId,
                              onCartUpdated: widget.onCartUpdated,
                            ),
                          ),
                        );
                      },

                      child: Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Image.network(
                                product.thumbnail,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (_, _, _) =>
                                    Icon(Icons.image, size: 24.sp),
                              ),
                            ),

                            Padding(
                              padding: EdgeInsets.all(8.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: product.title,
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text:
                                        '\$${product.price.toStringAsFixed(2)}',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
