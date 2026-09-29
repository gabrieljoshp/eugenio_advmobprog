# Lab Activity 6: Discussion

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

---

## 7. User model, service, and profile screen
The profile flow uses the same layered design as the cart flow. The `User` model in `lib/models/user.dart` defines the typed user data used by the UI, including:

- `id`
- `username`
- `email`
- `firstName` and `lastName`
- `gender`
- `image`
- `accessToken` and `refreshToken`

`User.fromJson()` converts the JSON returned by DummyJSON into a `User` object. The model also provides `displayName`, which combines the first and last name and falls back to the username when those fields are empty. `toJson()` provides the reverse conversion when a map representation is needed.

### Login and saved user data
`UserService` in `lib/services/user_service.dart` owns the authentication request and local persistence:

1. `SignInScreen` validates the form and calls `UserService.loginUser(username, password)`.
2. `loginUser()` sends `POST https://dummyjson.com/auth/login`.
3. On a successful response, the service saves the returned fields through `saveUserData()` and returns the response map.
4. `saveUserData()` converts the response to a `User` model, then stores the user's fields and tokens in `SharedPreferences`.
5. `SignInScreen` converts the response to `User.fromJson(response)` and passes that object to `HomeScreen`.

The service also exposes `getUserData()` to rebuild a raw map from `SharedPreferences`, `getUser()` to rebuild a typed `User`, and `isLoggedIn()` to check whether a saved token exists. `logout()` removes the saved profile fields and tokens.

### Rendering the profile
`HomeScreen` receives the authenticated `User` and passes it to `ProfileScreen(user: widget.user)`. `ProfileScreen` does not make an HTTP request or read raw JSON. It renders the supplied model values directly:

- `user.image` is displayed in a `CircleAvatar` when available.
- `user.displayName` and `user.username` identify the account.
- `user.email`, `user.gender`, and `user.id` are shown in the profile details.
- The logout button calls `UserService.logout()` and returns to `SignInScreen`.

This separation keeps authentication and persistence in the service, data conversion in the model, and presentation and user actions in the screen.

---

## 8. Using saved user data to render `CartScreen`
The saved user data supplies the `userId` needed by the cart endpoint. After login, the same `User` object is held by `HomeScreen`, so the navigation is:

```dart
CartScreen(
  userId: widget.user.id,
  cartUpdates: _cartUpdates,
)
```

When `CartScreen` starts, `_loadCart()` calls:

```dart
_cartFuture = CartService().getCartsByUserId(widget.userId);
```

`CartService` requests `GET https://dummyjson.com/carts/user/{userId}`, decodes the `carts` array, and maps each entry to a `Cart` model. `CartScreen` uses `FutureBuilder<List<Cart>>` to show a loading indicator while the request is pending, an error message when the request fails, and `No cart found` when no cart is returned. When data exists, it renders the first cart for that user and displays each `CartProduct` with its thumbnail, title, price, quantity, and totals.

The cart screen also maintains `_cart` as local state. Quantity changes update that local model immediately and recalculate the totals. Products added from the catalog return a `Cart` through the `cartUpdates` `ValueNotifier`; `CartScreen` listens for those updates and merges them into the displayed cart. This is necessary because DummyJSON accepts `POST /carts/add` but does not persist the simulated change for a later `GET`. A refresh therefore starts with the API cart and reapplies the locally received add-to-cart responses.

When a cart product is tapped, the screen uses its product ID to request the complete product from `ProductService`, then opens the shared `ProductDetailScreen`. The cart remains responsible for cart state, while the product detail screen remains responsible for product information.

---

## 9. Updated design pattern in this activity
The activity now demonstrates a layered model-service-screen pattern with local persistence and explicit data flow:

### Model layer
`User`, `Cart`, and `CartProduct` represent API data as typed Dart objects. Their JSON conversion methods prevent screens from depending on loosely typed response maps.

### Service layer
`UserService`, `CartService`, and `ProductService` encapsulate HTTP requests, response decoding, local user persistence, and API error handling. Screens call service methods instead of constructing requests themselves.

### Screen layer
`SignInScreen`, `HomeScreen`, `ProfileScreen`, and `CartScreen` coordinate user interaction and rendering. They receive models or IDs, display loading/error/content states, and pass data to the next screen when navigation is needed.

### Persistence and state flow
`SharedPreferences` preserves the authenticated user's profile fields and tokens between service calls. The saved `User.id` becomes the key that scopes cart retrieval. `HomeScreen` shares the authenticated user and a `ValueNotifier` for cart updates with its child screens, allowing catalog additions to appear in the cart without placing global state or HTTP code inside the widgets.

This updated pattern is easier to maintain because each layer has one primary responsibility: models describe data, services acquire and persist data, and screens render data and respond to user actions. It also makes the API flow reusable: the same user ID can drive profile-related behavior and user-specific cart requests without duplicating authentication or parsing logic.

---

## 10. DummyJSON and Firebase authentication workflow

The app supports two explicit login types through `LoginType`:

### DummyJSON workflow

1. The user selects `DummyJSON` and enters the demo username and password.
2. `SignInScreen` calls `UserService.loginUser()`.
3. `UserService` sends `POST https://dummyjson.com/auth/login` with `username`, `password`, and `expiresInMins`.
4. The response is converted to `User`, and the access and refresh tokens plus profile fields are saved in `SharedPreferences`.
5. `SplashScreen` checks the saved access token on later launches and opens `HomeScreen` when it is present.

DummyJSON is a simulated API. Its user data and login tokens are useful for demonstrating HTTP requests and model mapping, but it is not a complete production account system. A simulated user registration should not be treated as persistent account creation.

### Firebase workflow

1. The user selects `Firebase` or opens the signup screen.
2. Signup validates first name, last name, age, contact number, username, email address, and password, then calls `UserService.createAccount()`.
3. Firebase Auth creates the account and the service updates the Firebase display name.
4. Sign-in calls `UserService.signIn()` with email and password.
5. The service obtains the Firebase ID token, stores the local profile snapshot, and records `LoginType.firebase`.
6. `getUserData()` refreshes the ID token through `getIdToken()` before returning profile data.
7. Password changes and account deletion reauthenticate the user before modifying the account. Logout calls Firebase sign-out and clears local session data.

### Main idea of `UserService`

`UserService` is the authentication boundary for the UI. Screens do not know how tokens are stored, how Firebase reauthentication works, or how DummyJSON responses are parsed. They call service methods and receive typed user data. Persisting `loginType` lets the splash screen and profile screen choose the correct session behavior after navigation or an app restart.

### Benefits of Firebase for this application

- Firebase securely manages passwords instead of storing them in the app.
- Firebase ID tokens refresh automatically and can be checked by a backend or Firebase Security Rules.
- Auth state survives app restarts and can be observed through `authStateChanges()`.
- Reauthentication protects sensitive actions such as password changes and account deletion.
- Firebase Authentication can be extended with email verification, password reset, providers, and custom claims without changing the screen-to-service boundary.
