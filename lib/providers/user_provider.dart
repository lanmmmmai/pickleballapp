import 'package:flutter/material.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  UserModel? currentUser;

  void setUser(UserModel user) {
    currentUser = user;
    notifyListeners();
  }
}