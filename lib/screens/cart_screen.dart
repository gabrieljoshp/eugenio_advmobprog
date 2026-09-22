import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import '../widgets/custom_text.dart';

class CartScreen extends StatefulWidget {
  final int userId;
  final ValueNotifier<List<Cart>> cartUpdates;

  const CartScreen({
    super.key,
    required this.userId,
    required this.cartUpdates,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Cart>> _cartFuture;

  // Local cart state
  Cart? _cart;
  int _appliedCartUpdateCount = 0;

  @override
  void initState() {
    super.initState();
    widget.cartUpdates.addListener(_handleCartUpdate);
    _loadCart();
  }

  void _handleCartUpdate() {
    if (!mounted) return;

    setState(() {
      _applyPendingCartUpdates();
    });
  }

  void _applyPendingCartUpdates() {
    final updates = widget.cartUpdates.value;
    for (var index = _appliedCartUpdateCount;
        index < updates.length;
        index++) {
      _cart = _mergeAddedCart(_cart, updates[index]);
    }
    _appliedCartUpdateCount = updates.length;
  }

  Cart _mergeAddedCart(Cart? currentCart, Cart addedCart) {
    if (currentCart == null) return addedCart;

    final currentProducts = {
      for (final product in currentCart.products) product.id: product,
    };

    for (final addedProduct in addedCart.products) {
      final currentProduct = currentProducts[addedProduct.id];
      if (currentProduct == null) {
        currentProducts[addedProduct.id] = addedProduct;
        continue;
      }

      final addedQuantity = addedProduct.quantity < 1
          ? 1
          : addedProduct.quantity;
      final quantity = currentProduct.quantity + addedQuantity;
      final unitDiscountedPrice = addedProduct.quantity > 0
          ? addedProduct.discountedTotal / addedProduct.quantity
          : addedProduct.price;
      currentProducts[addedProduct.id] = CartProduct(
        id: addedProduct.id,
        title: addedProduct.title,
        price: addedProduct.price,
        quantity: quantity,
        total: addedProduct.price * quantity,
        discountPercentage: addedProduct.discountPercentage,
        discountedTotal: unitDiscountedPrice * quantity,
        thumbnail: addedProduct.thumbnail,
      );
    }

    final products = currentProducts.values.toList();

    return Cart(
      id: currentCart.id,
      products: products,
      total: products.fold<double>(0, (sum, product) => sum + product.total),
      discountedTotal: products.fold<double>(
        0,
        (sum, product) => sum + product.discountedTotal,
      ),
      userId: currentCart.userId,
      totalProducts: products.length,
      totalQuantity:
          products.fold<int>(0, (sum, product) => sum + product.quantity),
    );
  }

  void _loadCart() {
    _cartFuture = CartService().getCartsByUserId(widget.userId);

    _cartFuture.then((carts) {
      if (!mounted) return;

      setState(() {
        if (carts.isNotEmpty) {
          // DummyJSON does not persist POST /carts/add. Reapply every local
          // add-to-cart response so items remain visible after the first load
          // or a manual refresh.
          _cart = carts.first;
          _appliedCartUpdateCount = 0;
        }
        _applyPendingCartUpdates();
      });
    });
  }

  Future<void> _openProduct(CartProduct cartProduct) async {
    try {
      final product = await ProductService().getProductById(
        cartProduct.id,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            product: product,
            userId: widget.userId,
            onCartUpdated: (cart) {
              widget.cartUpdates.value = [...widget.cartUpdates.value, cart];
            },
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load product: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // LOCAL QUANTITY UPDATE
  // ============================================================

  void _updateProductQuantity(
    CartProduct cartProduct, {
    required int delta,
  }) {
    if (_cart == null) return;

    final updatedProducts = _cart!.products.map((product) {
      if (product.id == cartProduct.id) {
        final newQuantity = product.quantity + delta;

        // Do not allow quantity below 1
        if (newQuantity < 1) {
          return product;
        }

        // Calculate new product total
        final newTotal = product.price * newQuantity;

        // Calculate discounted total safely
        final newDiscountedTotal =
            product.quantity > 0
                ? (product.discountedTotal / product.quantity) *
                    newQuantity
                : product.discountedTotal;

        return CartProduct(
          id: product.id,
          title: product.title,
          price: product.price,
          quantity: newQuantity,
          total: newTotal,
          discountPercentage: product.discountPercentage,
          discountedTotal: newDiscountedTotal,
          thumbnail: product.thumbnail,
        );
      }

      return product;
    }).toList();

    // Recalculate cart total
    final updatedTotal = updatedProducts.fold<double>(
      0,
      (sum, product) => sum + product.total,
    );

    // Recalculate discounted total
    final updatedDiscountedTotal = updatedProducts.fold<double>(
      0,
      (sum, product) => sum + product.discountedTotal,
    );

    // Recalculate total quantity
    final updatedTotalQuantity = updatedProducts.fold<int>(
      0,
      (sum, product) => sum + product.quantity,
    );

    setState(() {
      _cart = Cart(
        id: _cart!.id,
        products: updatedProducts,
        total: updatedTotal,
        discountedTotal: updatedDiscountedTotal,
        userId: _cart!.userId,
        totalProducts: updatedProducts.length,
        totalQuantity: updatedTotalQuantity,
      );
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  void dispose() {
    widget.cartUpdates.removeListener(_handleCartUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Cart>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _cart == null) {
            return const Center(
              child: CircularProgressIndicator(),
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

          final carts = snapshot.data ?? [];

          if (carts.isEmpty && _cart == null) {
            return Center(
              child: CustomText(
                text: 'No cart found',
                fontSize: 16.sp,
              ),
            );
          }

          // Use local cart if available.
          // Otherwise, use the API cart.
          final cart = _cart ?? carts.first;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _cart = null;
                _loadCart();
              });

              await _cartFuture;
            },

            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                ...cart.products.map((cartProduct) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: InkWell(
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
                                borderRadius:
                                    BorderRadius.circular(12.r),

                                child: Image.network(
                                  cartProduct.thumbnail,
                                  width: 80.w,
                                  height: 80.h,
                                  fit: BoxFit.cover,

                                  errorBuilder: (_, _, _) {
                                    return Container(
                                      width: 80.w,
                                      height: 80.h,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,

                                      child: Icon(
                                        Icons.image,
                                        size: 26.sp,
                                      ),
                                    );
                                  },
                                ),
                              ),

                              SizedBox(width: 12.w),

                              // PRODUCT INFORMATION
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                  children: [
                                    // PRODUCT TITLE
                                    CustomText(
                                      text: cartProduct.title,
                                      fontSize: 17.sp,
                                      fontWeight:
                                          FontWeight.w600,
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),

                                    SizedBox(height: 6.h),

                                    // PRICE
                                    CustomText(
                                      text:
                                          '\$${cartProduct.price.toStringAsFixed(2)}',
                                      fontSize: 16.sp,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),

                                    SizedBox(height: 6.h),

                                    Row(
                                      children: [
                                        // ITEM QUANTITY TEXT
                                        CustomText(
                                          text:
                                              '${cartProduct.quantity} '
                                              '${cartProduct.quantity > 1 ? 'items' : 'item'}',
                                          fontSize: 12.sp,
                                        ),

                                        const Spacer(),

                                        // QUANTITY CONTROLS
                                        Row(
                                          children: [
                                            // MINUS BUTTON
                                            _quantityButton(
                                              Icons.remove,
                                              () =>
                                                  _updateProductQuantity(
                                                cartProduct,
                                                delta: -1,
                                              ),
                                            ),

                                            SizedBox(width: 8.w),

                                            // QUANTITY DISPLAY
                                            Container(
                                              width: 34.w,
                                              height: 34.h,
                                              alignment:
                                                  Alignment.center,

                                              decoration:
                                                  BoxDecoration(
                                                color:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .surface,

                                                borderRadius:
                                                    BorderRadius.circular(
                                                  9.r,
                                                ),
                                              ),

                                              child: CustomText(
                                                text:
                                                    '${cartProduct.quantity}',
                                                fontSize: 14.sp,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),

                                            SizedBox(width: 8.w),

                                            // PLUS BUTTON
                                            _quantityButton(
                                              Icons.add,
                                              () =>
                                                  _updateProductQuantity(
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
                    ),
                  );
                }),

                SizedBox(height: 12.h),
                Card(
                  elevation: 2,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),

                  child: Padding(
                    padding: EdgeInsets.all(16.r),

                    child: Column(
                      children: [
                        // SUBTOTAL
                        Row(
                          children: [
                            CustomText(
                              text: 'Subtotal:',
                              fontSize: 16.sp,
                            ),

                            const Spacer(),

                            CustomText(
                              text:
                                  '\$${cart.total.toStringAsFixed(2)}',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ],
                        ),

                        SizedBox(height: 10.h),

                        // DELIVERY
                        Row(
                          children: [
                            CustomText(
                              text: 'Delivery:',
                              fontSize: 16.sp,
                            ),

                            const Spacer(),

                            CustomText(
                              text: '\$0.00',
                              fontSize: 16.sp,
                            ),
                          ],
                        ),

                        SizedBox(height: 12.h),

                        Divider(
                          color: Theme.of(context).dividerColor,
                        ),

                        SizedBox(height: 12.h),

                        // TOTAL
                        Row(
                          children: [
                            CustomText(
                              text: 'Total:',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                            ),

                            const Spacer(),

                            CustomText(
                              text:
                                  '\$${cart.total.toStringAsFixed(2)}',
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

                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Order confirmed successfully!',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFFFD41D),

                      foregroundColor:
                          const Color(0xFF1F2A5A),

                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12.r),
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

                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _quantityButton(
    IconData icon,
    VoidCallback onPressed,
  ) {
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

        child: Icon(
          icon,
          color: const Color(0xFF1F2A5A),
          size: 18.sp,
        ),
      ),
    );
  }
}
