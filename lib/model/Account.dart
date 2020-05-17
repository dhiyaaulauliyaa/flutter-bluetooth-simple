import 'package:flutter/material.dart';

class Account {
  String name;
  String phone;
  String savedDeviceId;

  Account({@required this.name, @required this.phone, this.savedDeviceId});
}
