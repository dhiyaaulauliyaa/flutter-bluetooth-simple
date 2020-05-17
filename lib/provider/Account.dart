import 'package:bluetooth_app/model/Account.dart';
import 'package:flutter/material.dart';

class AccountProvider with ChangeNotifier {
  Account user = Account(
    name: 'Ahmad Dhiyaaul Auliyaa',
    phone: '081290006048',
    savedDeviceId: '08:8398:DF93:94JS:SIJD:10',
  );

  Account getUser() => user;
  void setDeviceId(String id) {
    user.savedDeviceId = id;

    notifyListeners();
  }
}
