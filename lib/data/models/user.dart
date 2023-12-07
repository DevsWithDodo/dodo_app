import 'package:csocsort_szamla/data/models/group.dart';
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String username;
  final int id;
  final String currency;
  final Group? group;
  final List<Group> groups;
  final bool ratedApp;
  final bool showAds;
  final bool useGradients;
  final bool personalisedAds;
  final bool trialVersion;
  final List paymentMethods;

  const User({
    required this.id,
    required this.username,
    required this.currency,
    this.group,
    this.groups = const [],
    this.ratedApp = false,
    this.showAds = false,
    this.useGradients = true,
    this.personalisedAds = false,
    this.trialVersion = false,
    this.paymentMethods = const [],
  });

  @override
  List<Object> get props => [id, username];

  User.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        username = json["username"],
        currency = json["currency"],
        group = json["group"] != null ? Group.fromJson(json["group"]) : null,
        groups = json["groups"] != null ? List<Group>.from(json["groups"].map((x) => Group.fromJson(x))) : [],
        ratedApp = json["ratedApp"],
        showAds = json["showAds"],
        useGradients = json["useGradients"],
        personalisedAds = json["personalisedAds"],
        trialVersion = json["trialVersion"],
        paymentMethods = json["paymentMethods"] != null ? List.from(json["paymentMethods"]) : [];

  Map<String, dynamic> toJson() => {
    "id": id,
    "username": username,
  };

  static const empty = User(id: 0, username: '', currency: 'HUF');

}