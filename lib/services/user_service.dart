import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart';
import '../models/login_type.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

ValueNotifier<UserService?> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      await _saveLoginType(LoginType.dummyJson);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// ** Save User Data to SharedPreferences **
  /// Save user data from API response based on User model
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(userData);
    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setInt('age', user.age);
    await prefs.setString('phone', user.phone);

    // Support generic token key if present in API response
    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  /// Retrieve user data from SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    if (currentUser != null) {
      // Rehydrate the local cache from Firestore when Firebase restores a
      // session after an app restart.
      await _saveFirebaseUser(currentUser!);
    }
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'age': prefs.getInt('age') ?? 0,
      'phone': prefs.getString('phone') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
    };
  }

  /// Retrieve User model from SharedPreferences
  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  /// **Check if User is Logged In**
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    if (currentUser != null) {
      await _saveFirebaseUser(currentUser!);
      return true;
    }
    if (await getLoginType() == LoginType.firebase) {
      return false;
    }
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  /// **Logout and Clear User Data**
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('id');
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('firstName');
      await prefs.remove('lastName');
      await prefs.remove('gender');
      await prefs.remove('image');
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('age');
      await prefs.remove('phone');
      await prefs.remove('token');
      await prefs.remove('loginType');
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  final firebase.FirebaseAuth firebaseAuth = firebase.FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  firebase.User? get currentUser => firebaseAuth.currentUser;

  Stream<firebase.User?> get authStateChanges =>
      firebaseAuth.authStateChanges();

  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('loginType') == LoginType.firebase.name
        ? LoginType.firebase
        : LoginType.dummyJson;
  }

  Future<void> _saveLoginType(LoginType loginType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', loginType.name);
  }

  Future<void> _saveFirebaseUser(firebase.User firebaseUser) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await firebaseUser.getIdToken() ?? '';
    final profile = await _getFirebaseProfile(firebaseUser.uid);
    await saveUserData({
      'id': firebaseUser.uid.hashCode,
      'username': firebaseUser.displayName ?? firebaseUser.email ?? '',
      'email': firebaseUser.email ?? '',
      'firstName': profile['firstName'] ?? prefs.getString('firstName') ?? '',
      'lastName': profile['lastName'] ?? prefs.getString('lastName') ?? '',
      'gender': profile['gender'] ?? prefs.getString('gender') ?? '',
      'image': firebaseUser.photoURL ?? '',
      'accessToken': token,
      'refreshToken': '',
      'age': profile['age'] ?? prefs.getInt('age') ?? 0,
      'phone': profile['phone'] ?? prefs.getString('phone') ?? '',
    });
    await _saveLoginType(LoginType.firebase);
  }

  Future<Map<String, dynamic>> _getFirebaseProfile(String uid) async {
    final document = await firestore.collection('users').doc(uid).get();
    return document.data() ?? {};
  }

  Future<void> _saveFirebaseProfile({
    required firebase.User firebaseUser,
    required String firstName,
    required String lastName,
    required String gender,
    int? age,
    String? phone,
  }) {
    return firestore.collection('users').doc(firebaseUser.uid).set({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'gender': gender.trim(),
      'email': firebaseUser.email ?? '',
      'username': firebaseUser.displayName ?? firebaseUser.email ?? '',
      if (age != null) 'age': age,
      if (phone != null) 'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<firebase.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) await _saveFirebaseUser(credential.user!);
    return credential;
  }

  Future<firebase.UserCredential> createAccount({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required String gender,
    required int age,
    required String phone,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      if (username.trim().isNotEmpty) {
        await credential.user!.updateDisplayName(username.trim());
      }
      await _saveFirebaseProfile(
        firebaseUser: credential.user!,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        age: age,
        phone: phone,
      );
      await _saveFirebaseUser(credential.user!);
    }
    return credential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    await logout();
  }

  Future<void> updateUsername({required String username}) async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) {
      throw StateError('No Firebase user is signed in.');
    }
    await firebaseUser.updateDisplayName(username.trim());
    await firestore.collection('users').doc(firebaseUser.uid).set({
      'username': username.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _saveFirebaseUser(firebaseUser);
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String gender,
  }) async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) {
      throw StateError('No Firebase user is signed in.');
    }
    await _saveFirebaseProfile(
      firebaseUser: firebaseUser,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
    );
    await _saveFirebaseUser(firebaseUser);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) {
      throw StateError('No Firebase user is signed in.');
    }
    final credential = firebase.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await firebaseUser.reauthenticateWithCredential(credential);
    await firestore.collection('users').doc(firebaseUser.uid).delete();
    await firebaseUser.delete();
    await signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) {
      throw StateError('No Firebase user is signed in.');
    }
    final credential = firebase.EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await firebaseUser.reauthenticateWithCredential(credential);
    await firebaseUser.updatePassword(newPassword);
  }
}
