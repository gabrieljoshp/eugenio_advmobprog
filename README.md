# Lab Activity 3: Discussion

## Overview
This activity uses a layered architecture that separates the data model, API service layer, and screen UI. The flow is:

1. The UI screen requests cart data from a service.
2. The service calls the DummyJSON API.
3. The response is converted into model objects.
4. The screen renders the model data into widgets.
5. When a cart item is tapped, the app fetches the product details by product ID and opens the same detail screen used by the product catalog.

This pattern keeps the app organized and easier to maintain.

---

## 1. Cart model
The cart data is represented by the model in `lib/models/cart.dart`.

```dart
class Cart {
  final int id;
  final List<CartProduct> products;
  final double total;
  final double discountedTotal;
  final int userId;
  final int totalProducts;
  final int totalQuantity;

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? 0,
      products: (json['products'] as List?)
              ?.map((e) => CartProduct.fromJson(e))
              .toList() ?? [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      discountedTotal: (json['discountedTotal'] as num?)?.toDouble() ?? 0.0,
      userId: json['userId'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalQuantity: json['totalQuantity'] ?? 0,
    );
  }
}
```

The `Cart` model translates the JSON from DummyJSON into clean Dart objects. Each cart item is also mapped as a `CartProduct` with values such as:

- `id`
- `title`
- `price`
- `quantity`
- `total`
- `thumbnail`

This is important because the UI does not work directly with raw JSON. Instead, it interacts with typed objects.

---

## 2. Cart service layer
The service layer in `lib/services/cart_service.dart` is responsible for fetching data from the API and returning model objects.

### Get cart by user ID
This app uses the endpoint:

```http
GET https://dummyjson.com/carts/user/{userId}
```

Example:

```dart
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
```

This is useful because the app needs the cart of a specific user, not all carts in the system. The API responds with an object that contains a `carts` array, and the app takes the first cart in that list for the current user.

### Get cart by cart ID
DummyJSON also supports:

```http
GET https://dummyjson.com/carts/{id}
```

This returns a single cart object directly, not a list. The implementation is similar:

```dart
Future<Cart> getCartById(int cartId) async {
  final response = await http.get(Uri.parse('$host/carts/$cartId'));

  if (response.statusCode == 200) {
    return Cart.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load cart with id $cartId');
  }
}
```

This endpoint is helpful when you want one specific cart rather than all carts for a user.

### Add to cart
The project also uses the cart add endpoint:

```http
POST https://dummyjson.com/carts/add
```

The request body is structured like this:

```json
{
  "userId": 5,
  "products": [
    {
      "id": 1,
      "quantity": 1
    }
  ]
}
```

The `CartService.addToCart()` method sends this payload, then decodes the result back into a `Cart` object.

---

## 3. How the screen uses the model and service
The screen that renders the cart is `lib/screens/cart_screen.dart`.

### Flow
- `CartScreen` receives `userId` from the parent screen.
- In `initState()`, it calls `_loadCart()`.
- `_loadCart()` assigns a `Future<List<Cart>>` from `CartService().getCartsByUserId(widget.userId)`.
- The UI uses `FutureBuilder` to wait for the API and then render the data.

```dart
late Future<List<Cart>> _cartFuture;

void _loadCart() {
  _cartFuture = CartService().getCartsByUserId(widget.userId);
}
```

Then inside the widget tree:

```dart
FutureBuilder<List<Cart>>(
  future: _cartFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    final carts = snapshot.data ?? [];
    if (carts.isEmpty) {
      return const Center(child: Text('No cart found'));
    }

    final cart = carts.first;
    return ListView(...);
  },
)
```

This means the screen is not directly making HTTP requests; it asks the service layer for the data and then uses the returned `Cart` model to render the UI.

---

## 4. Rendering the cart items and navigating to the detail screen
Each item in the cart is displayed as a card. The card includes:

- image
- product title
- price
- quantity
- +/- quantity controls
- summary area and confirm button

When the user taps a product card, the app does not open the cart item itself. Instead, it fetches the product details using the product ID and navigates to the same detail screen used by the product catalog.

```dart
Future<void> _openProduct(CartProduct cartProduct) async {
  try {
    final product = await ProductService().getProductById(cartProduct.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load product: $e')),
    );
  }
}
```

This is an important design decision: the cart screen is about cart metadata, but the detail screen is the reusable product detail view. The cart item only provides the `productId`, and the app loads the full product details from the product endpoint before showing the detail page.

This is why both the product list and cart screen can route to the same `ProductDetailScreen`.

---

## 5. Updated design pattern in this activity
The updated pattern is a clean model-service-screen architecture, sometimes described as a layered MVC/MVVM-inspired approach:

### Model
- holds the raw data structure (`Cart`, `CartProduct`)
- converts API JSON into Dart objects

### Service
- handles all HTTP calls
- encapsulates API endpoints and request/response logic
- returns domain models rather than raw `Map` objects

### Screen
- listens to the service result through `FutureBuilder`
- renders the data using widgets
- handles user actions like tapping an item or updating quantity

This design is better than placing network code directly in the widget because:

- the screen remains focused on UI rendering
- the service can be reused elsewhere
- the model gives predictable data types
- the project is easier to test and extend

---

## 6. Summary
The cart flow works like this:

1. `HomeScreen` passes `userId` to `CartScreen`.
2. `CartScreen` calls `CartService.getCartsByUserId(userId)`.
3. The service fetches `GET /carts/user/{userId}`.
4. The JSON is converted into `Cart` and `CartProduct` objects.
5. The screen uses `FutureBuilder` to show the cart items.
6. When a product is tapped, the app calls `ProductService.getProductById(productId)`.
7. The fetched product is passed into the same `ProductDetailScreen`.

This creates a consistent, reusable, and maintainable pattern for rendering data from multiple DummyJSON endpoints.
