import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';

class CartService {
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];

      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  Future<List<Cart>> getCartsByUserId(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];

      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cart for user $userId');
    }
  }

  Future<Cart> addToCart({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': productId, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add product to cart');
    }
  }

  Future<Cart> updateCart({
    required int cartId,
    required List<Map<String, dynamic>> products,
    bool merge = false,
  }) async {
    final response = await http.put(
      Uri.parse('$host/carts/$cartId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'merge': merge, 'products': products}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update cart');
    }
  }
}
