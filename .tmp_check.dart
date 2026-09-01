import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final response = await http.post(
    Uri.parse('https://dummyjson.com/carts/add'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'userId': 5,
      'products': [
        {'id': 1, 'quantity': 1},
      ],
    }),
  );

  print('status=${response.statusCode}');
  print(response.body);
}
