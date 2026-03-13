import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? token;
  String? email;
  String? userName;
  String? phone;
  String? role;
  String? avatarUrl;
  String? coverUrl;
  List<String> paymentMethods = [];
  bool isVerified = false;

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  void setLoginData({
    required String tokenValue,
    required String emailValue,
    required String nameValue,
    String? phoneValue,
    String? roleValue,
    List<String>? paymentMethodsValue,
    String? avatarUrlValue,
    String? coverUrlValue,
  }) {
    token = tokenValue;
    email = emailValue;
    userName = nameValue;
    phone = phoneValue ?? '';
    role = roleValue ?? 'USER';
    paymentMethods = paymentMethodsValue ?? ['Tiền mặt'];
    avatarUrl = avatarUrlValue ?? '';
    coverUrl = coverUrlValue ?? '';
    isVerified = true;
    notifyListeners();
  }

  void setPendingEmail(String value) {
    email = value;
    notifyListeners();
  }

  void updateProfile({
    required String nameValue,
    required String phoneValue,
    required List<String> paymentMethodsValue,
    String? avatarUrlValue,
    String? coverUrlValue,
  }) {
    userName = nameValue;
    phone = phoneValue;
    paymentMethods = paymentMethodsValue;
    avatarUrl = avatarUrlValue ?? avatarUrl;
    coverUrl = coverUrlValue ?? coverUrl;
    notifyListeners();
  }

  void logout() {
    token = null;
    email = null;
    userName = null;
    phone = null;
    role = null;
    avatarUrl = null;
    coverUrl = null;
    paymentMethods = [];
    isVerified = false;
    notifyListeners();
  }
}
