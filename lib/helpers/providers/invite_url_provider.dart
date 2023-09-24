import 'package:flutter/material.dart';

class InviteUrlProvider extends ChangeNotifier {
  String? _inviteUrl = null;

  InviteUrlProvider(this._inviteUrl);

  String? get inviteUrl => _inviteUrl;

  set inviteUrl(String? value) {
    _inviteUrl = value;
    notifyListeners();
  }
}