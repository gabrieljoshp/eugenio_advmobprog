import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

class ProductService {
  Future<List<Product>> getAllProducts() async {
    // DummyJSON is the catalog source for every account type. Keep product
    // requests independent of Firebase credentials and login state.
    final baseUrl = (host ?? 'https://dummyjson.com').replaceAll(RegExp(r'/$'), '');
    const int pageSize = 100;
    int skip = 0;
    final List<Product> allProducts = [];

    while (true) {
      final response = await http.get(
        Uri.parse('$baseUrl/products?limit=$pageSize&skip=$skip'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load products');
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final List productsJson = data['products'] ?? [];

      if (productsJson.isEmpty) {
        break;
      }

      allProducts.addAll(
        productsJson.map((json) => Product.fromJson(json)).toList(),
      );

      final total = data['total'] as int? ?? allProducts.length;
      if (allProducts.length >= total || productsJson.length < pageSize) {
        break;
      }

      skip += productsJson.length;
    }

    return allProducts;
  }

  Future<Product> getProductById(int id) async {
    final baseUrl = (host ?? 'https://dummyjson.com').replaceAll(RegExp(r'/$'), '');
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id'),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(
        jsonDecode(response.body),
      );
    } else {
      throw Exception('Failed to load product');
    }
  }
}
