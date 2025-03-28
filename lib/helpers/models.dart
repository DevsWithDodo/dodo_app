import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  String apiToken;
  String? username;
  int id;
  Currency currency;
  Group? group;
  List<Group> groups;
  bool ratedApp;
  bool showAds;
  bool useGradients;
  bool personalisedAds;
  bool trialVersion;
  List<PaymentMethod> paymentMethods;
  UserStatus userStatus;
  bool googleConnected;
  bool appleConnected;
  bool hasPassword;

  User({
    required this.apiToken,
    this.username,
    required this.id,
    required this.currency,
    required this.userStatus,
    required this.googleConnected,
    required this.appleConnected,
    required this.hasPassword,
    this.group,
    this.groups = const [],
    this.ratedApp = false,
    this.showAds = false,
    this.useGradients = true,
    this.personalisedAds = false,
    this.trialVersion = false,
    this.paymentMethods = const [],
  });

  factory User.fromJson(Map<String, dynamic> json, [bool? ratedApp]) {
    return User(
      apiToken: json['api_token'],
      username: json['username'],
      id: json['id'],
      currency: Currency.fromCode(json['default_currency'], safe: true),
      ratedApp: ratedApp ?? false,
      personalisedAds: json['personalised_ads'] == 1,
      showAds: json['ad_free'] == 0,
      useGradients: json['gradients_enabled'] == 1,
      trialVersion: json['trial'] == 1,
      paymentMethods: json['payment_details'] != null
          ? PaymentMethod.fromJsonList(
              jsonDecode(json['payment_details']) as List,
            )
          : [],
      userStatus: json['status'] != null
          ? UserStatus.fromJson(json['status'])
          : UserStatus(
              // This should never happen, but just in case
              trialStatus: TrialStatus.seen,
              pinVerifiedAt: DateTime.now(),
              pinVerificationCount: 100,
            ),
      googleConnected: json['google_connected'] == 1,
      appleConnected: json['apple_connected'] == 1,
      hasPassword: json['has_password'] == 1,
    );
  }

  factory User.fromPreferences(SharedPreferences preferences) {
    List<String> usersGroupNames = preferences.getStringList('users_groups') ?? [];
    List<int> usersGroupIds = preferences.getStringList('users_group_ids')?.map((e) => int.parse(e)).toList() ?? [];
    List<String> usersGroupCurrencies = preferences.getStringList('users_group_currencies') ?? [];
    return User(
      apiToken: preferences.getString('api_token')!,
      username: preferences.getString('current_username'),
      id: preferences.getInt('current_user_id')!,
      currency: Currency.fromCode(preferences.getString('current_user_currency') ?? 'EUR', safe: true),
      group: preferences.containsKey('current_group_id')
          ? Group(
              id: preferences.getInt('current_group_id')!,
              name: preferences.getString('current_group_name')!,
              currency: Currency.fromCode(preferences.getString('current_group_currency') ?? 'EUR', safe: true),
            )
          : null,
      groups: usersGroupNames
          .asMap()
          .map((index, value) => MapEntry(
              index,
              Group(
                id: usersGroupIds[index],
                name: value,
                currency: Currency.fromCode(
                  usersGroupCurrencies.length > index ? usersGroupCurrencies[index] : 'EUR',
                  safe: true,
                ),
              )))
          .values
          .toList(),
      ratedApp: preferences.getBool('rated_app') ?? false,
      paymentMethods: [],
      userStatus: UserStatus(
        pinVerificationCount: 100,
        pinVerifiedAt: DateTime.now(),
        trialStatus: TrialStatus.seen,
      ),
      googleConnected: false,
      appleConnected: false,
      hasPassword: false,
    );
  }

  User mergeWith(User otherUser) {
    return User(
      apiToken: otherUser.apiToken,
      username: otherUser.username ?? username,
      id: otherUser.id,
      currency: otherUser.currency,
      group: otherUser.group ?? group,
      groups: otherUser.groups.isNotEmpty ? otherUser.groups : groups,
      ratedApp: otherUser.ratedApp,
      showAds: otherUser.showAds,
      useGradients: otherUser.useGradients,
      personalisedAds: otherUser.personalisedAds,
      trialVersion: otherUser.trialVersion,
      paymentMethods: otherUser.paymentMethods.isNotEmpty ? otherUser.paymentMethods : paymentMethods,
      userStatus: otherUser.userStatus,
      googleConnected: otherUser.googleConnected,
      appleConnected: otherUser.appleConnected,
      hasPassword: otherUser.hasPassword,
    );
  }
}

enum TrialStatus {
  trial,
  expired,
  seen;

  const TrialStatus();

  static TrialStatus fromString(String trialStatus) {
    switch (trialStatus) {
      case 'trial':
        return TrialStatus.trial;
      case 'expired':
        return TrialStatus.expired;
      case 'seen':
        return TrialStatus.seen;
      default:
        return TrialStatus.seen;
    }
  }
}

class UserStatus {
  TrialStatus trialStatus;
  DateTime pinVerifiedAt;
  int pinVerificationCount;

  UserStatus({
    required this.trialStatus,
    required this.pinVerifiedAt,
    required this.pinVerificationCount,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      trialStatus: TrialStatus.fromString(json['trial_status']),
      pinVerifiedAt: DateTime.parse(json['pin_verified_at']).toLocal(),
      pinVerificationCount: json['pin_verification_count'],
    );
  }

  UserStatus copyWith({
    TrialStatus? trialStatus,
    DateTime? pinVerifiedAt,
    int? pinVerificationCount,
  }) {
    return UserStatus(
      trialStatus: trialStatus ?? this.trialStatus,
      pinVerifiedAt: pinVerifiedAt ?? this.pinVerifiedAt,
      pinVerificationCount: pinVerificationCount ?? this.pinVerificationCount,
    );
  }
}

class Guest {
  int id;
  String nickname;
  int groupId;

  Guest({
    required this.id,
    required this.nickname,
    required this.groupId,
  });
}

class PaymentMethod {
  String name;
  String value;
  bool priority;

  PaymentMethod({required this.name, required this.value, required this.priority});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      name: json['name'],
      value: json['value'],
      priority: json['priority'],
    );
  }

  static List<PaymentMethod> fromJsonList(List<dynamic> json) {
    return json.map((e) => PaymentMethod.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'priority': priority,
    };
  }

  PaymentMethod clone() {
    return PaymentMethod(
      name: name,
      value: value,
      priority: priority,
    );
  }

  factory PaymentMethod.empty() {
    return PaymentMethod(
      name: '',
      value: '',
      priority: false,
    );
  }
}

class Member {
  int id;
  String? username;
  late String nickname;
  double balance;
  late double balanceOriginalCurrency;
  bool? isCustomAmount;
  bool? isGuest;
  String? apiToken;
  bool? isAdmin;
  List<PaymentMethod>? paymentMethods;
  Member({
    required this.id,
    this.username,
    required this.nickname,
    required this.balance,
    this.isAdmin,
    this.apiToken,
    double? balanceOriginalCurrency,
    this.isCustomAmount,
    this.isGuest,
    this.paymentMethods,
  }) {
    this.balanceOriginalCurrency = balanceOriginalCurrency ?? balance;
  }
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      username: json['username'],
      id: json['user_id'],
      nickname: json['nickname'],
      balance: json['balance'] * 1.0,
      isAdmin: json['is_admin'] == 1,
      balanceOriginalCurrency: (json['original_balance'] ?? json['balance']) * 1.0,
      isCustomAmount: json['custom_amount'] ?? false,
      isGuest: json['is_guest'] == 1,
      paymentMethods: json['payment_details'] != null ? (jsonDecode(json['payment_details']) as List).map<PaymentMethod>((paymentMethod) => PaymentMethod.fromJson(paymentMethod)).toList() : null,
    );
  }

  @override
  String toString() {
    return nickname;
  }

  Map toJson() {
    return {'user_id': id};
  }
}

class Group {
  Currency currency;
  String name;
  int id;
  bool? adminApproval;
  Group({
    required this.name,
    required this.id,
    required this.currency,
    this.adminApproval,
  });

  factory Group.fromJson(Map<String, dynamic> json, [bool safeCurrency = false]) {
    return Group(
      name: json['group_name'],
      id: json['group_id'],
      currency: Currency.fromCode(json['currency'], safe: safeCurrency),
    );
  }

  static List<Group> fromJsonList(List<dynamic> json, [bool safeCurrency = false]) {
    return json.map((e) => Group.fromJson(e, safeCurrency)).toList();
  }
}

class Reaction {
  static const List<String> possibleReactions = ['👍', '❤', '😲', '😥', '❗', '❓'];
  String reaction;
  String nickname;
  int userId;
  Reaction({
    required this.reaction,
    required this.nickname,
    required this.userId,
  });
  factory Reaction.fromJson(Map<String, dynamic> reaction) {
    return Reaction(reaction: reaction['reaction'], nickname: reaction['user_nickname'], userId: reaction['user_id']);
  }
  @override
  String toString() {
    return reaction;
  }
}

class Purchase {
  int id;
  late String buyerNickname;
  int buyerId;
  List<Member> receivers;
  double totalAmount;
  late double totalAmountOriginalCurrency;
  String name;
  late Currency originalCurrency;
  DateTime updatedAt;
  Category? category;
  List<Reaction>? reactions;

  Purchase({
    required this.id,
    required this.name,
    required this.buyerId,
    required this.buyerNickname,
    required this.receivers,
    required this.totalAmount,
    double? totalAmountOriginalCurrency,
    required this.originalCurrency,
    required this.updatedAt,
    this.reactions,
    this.category,
  }) {
    this.totalAmountOriginalCurrency = totalAmountOriginalCurrency ?? totalAmount;
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['purchase_id'],
      name: json['name'],
      updatedAt: json['updated_at'] == null ? DateTime.now() : DateTime.parse(json['updated_at']).toLocal(),
      originalCurrency: Currency.fromCode(json['original_currency']),
      buyerId: json['buyer_id'],
      buyerNickname: json['buyer_nickname'],
      totalAmount: (json['total_amount'] * 1.0),
      totalAmountOriginalCurrency: (json['original_total_amount'] ?? json['original_currency']) * 1.0,
      receivers: json['receivers'].map<Member>((element) => Member.fromJson(element)).toList(),
      reactions: json['reactions'].map<Reaction>((reaction) => Reaction.fromJson(reaction)).toList(),
      category: Category.fromName(json["category"]),
    );
  }

  factory Purchase.example(String name, double amount, Currency currency, Member buyer, List<Member> receivers, [List<Reaction> reactions = const []]) {
    return Purchase(
      id: 0,
      name: name,
      updatedAt: DateTime.now(),
      originalCurrency: currency,
      buyerId: buyer.id,
      buyerNickname: buyer.nickname,
      totalAmount: amount,
      totalAmountOriginalCurrency: amount,
      receivers: receivers,
      reactions: [],
    );
  }
}

class Payment {
  int id;
  double amount;
  late double amountOriginalCurrency;
  DateTime updatedAt;
  String payerNickname, takerNickname;
  late String note;
  int payerId, takerId;
  List<Reaction>? reactions;
  Currency originalCurrency;

  Payment({
    required this.id,
    required this.amount,
    double? amountOriginalCurrency,
    required this.payerId,
    required this.payerNickname,
    required this.takerId,
    required this.takerNickname,
    String? note,
    required this.originalCurrency,
    required this.updatedAt,
    this.reactions,
  }) {
    this.amountOriginalCurrency = amountOriginalCurrency ?? amount;
    this.note = note ?? '';
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['payment_id'],
      amount: (json['amount'] * 1.0),
      updatedAt: json['updated_at'] == null ? DateTime.now() : DateTime.parse(json['updated_at']).toLocal(),
      payerId: json['payer_id'],
      payerNickname: json['payer_nickname'],
      takerId: json['taker_id'],
      takerNickname: json['taker_nickname'],
      note: json['note'],
      originalCurrency: Currency.fromCode(json['original_currency']),
      amountOriginalCurrency: (json['original_amount'] ?? json['amount']) * 1.0,
      reactions: json['reactions'].map<Reaction>((reaction) => Reaction.fromJson(reaction)).toList(),
    );
  }
}

enum CategoryType {
  food,
  groceries,
  transport,
  entertainment,
  shopping,
  health,
  bills,
  other,
}

class Category {
  CategoryType type;
  IconData icon;
  String text;
  Category({required this.type, required this.icon, required this.text});

  String tr() {
    return "categories.$text".tr();
  }

  static Category? fromName(String? categoryName) {
    return Category.categories.firstWhereOrNull((category) => category.text == categoryName);
  }

  static Category? fromType(CategoryType? type) {
    return Category.categories.firstWhereOrNull((category) => category.type == type);
  }

  static List<Category> categories = [
    Category(type: CategoryType.food, icon: Icons.fastfood, text: 'food'),
    Category(
      type: CategoryType.groceries,
      icon: Icons.shopping_basket,
      text: 'groceries',
    ),
    Category(type: CategoryType.transport, icon: Icons.train, text: 'transport'),
    Category(
      type: CategoryType.entertainment,
      icon: Icons.movie_filter,
      text: 'entertainment',
    ),
    Category(
      type: CategoryType.shopping,
      icon: Icons.shopping_bag,
      text: 'shopping',
    ),
    Category(
      type: CategoryType.health,
      icon: Icons.health_and_safety,
      text: 'health',
    ),
    Category(type: CategoryType.bills, icon: Icons.house, text: 'bills'),
    Category(type: CategoryType.other, icon: Icons.category, text: 'other'),
  ];

  @override
  bool operator ==(Object other) => identical(this, other) || other is Category && runtimeType == other.runtimeType && type == other.type && icon == other.icon && text == other.text;

  @override
  int get hashCode => type.hashCode ^ icon.hashCode ^ text.hashCode;
}

class ShoppingRequest {
  int id;
  String name;
  String requesterNickname;
  int requesterId;
  DateTime updatedAt;
  List<Reaction>? reactions;

  ShoppingRequest({
    required this.id,
    required this.name,
    required this.requesterId,
    required this.requesterNickname,
    required this.updatedAt,
    this.reactions,
  });

  factory ShoppingRequest.fromJson(Map<String, dynamic> json) {
    return ShoppingRequest(
      id: json['request_id'],
      requesterId: json['requester_id'],
      requesterNickname: json['requester_nickname'] ?? 'asda',
      name: json['name'],
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
      reactions: (json['reactions'] ?? []).map<Reaction>((reaction) => Reaction.fromJson(reaction)).toList(),
    );
  }

  ShoppingRequest clone() {
    return ShoppingRequest(
      id: id,
      name: name,
      requesterId: requesterId,
      requesterNickname: requesterNickname,
      updatedAt: updatedAt,
    );
  }

  @override
  String toString() {
    return '$name; $updatedAt; ${reactions!.join(', ')}';
  }
}

class ReceiptInformation {
  File imageFile;
  String storeName;
  Currency currency;
  List<ReceiptItem> items;

  ReceiptInformation({
    required this.imageFile,
    required this.storeName,
    required this.currency,
    required this.items,
  });

  double get totalCost => items.fold(0, (prev, current) => prev + current.cost);

  factory ReceiptInformation.fromJson(Map<String, dynamic> json, File imageFile) {
    json['items'] = (json['items'] as List<dynamic>).map((item) => item as Map<String, dynamic>).toList();
    var groupedByName = groupBy(json['items'] as List<Map<String, dynamic>>, (Map<String, dynamic> item) => item['item_name']).values.toList();
    List<List<Map<String, dynamic>>> groupedByNameCost = [];
    for (var group in groupedByName) {
      var groupedByCost = groupBy(group, (Map<String, dynamic> item) => item['cost']).values.toList();
      for (var groupCost in groupedByCost) {
        groupedByNameCost.add(groupCost);
      }
    }

    List<ReceiptItem> items = groupedByNameCost.map<ReceiptItem>((group) {
      var item = group.first;
      item['cost'] *= group.length; // Same cost items are grouped together
      item['discount'] *= group.length;
      return ReceiptItem.fromJson(item);
    }).toList();

    return ReceiptInformation(
      storeName: json['store_name'],
      currency: Currency.fromCode(json['currency_code_iso_4217'], safe: true),
      items: items,
      imageFile: imageFile,
    );
  }

  factory ReceiptInformation.dummy(File imageFile) {
    return ReceiptInformation(
      storeName: 'Dummy Store',
      currency: Currency.fromCode('HUF'),
      items: [
        ReceiptItem(itemName: 'Item 1', baseCost: 100000, discount: 0, assignedAmounts: {}),
        ReceiptItem(itemName: 'Item 2', baseCost: 200000, discount: 0, assignedAmounts: {}),
        ReceiptItem(itemName: 'Item 3', baseCost: 300000, discount: 0, assignedAmounts: {}),
        ReceiptItem(itemName: 'Item 4', baseCost: 400000, discount: 0, assignedAmounts: {}),
        ReceiptItem(itemName: 'Item 5', baseCost: 500000, discount: 0, assignedAmounts: {}),
        ReceiptItem(itemName: 'Item 6', baseCost: 600000, discount: 0, assignedAmounts: {}),
      ],
      imageFile: imageFile,
    );
  }
}

class ReceiptItem {
  String itemName;
  double baseCost;
  double discount;
  double cost;

  /// Map from member id to amount assigned to that member
  Map<int, int> assignedAmounts = {};

  ReceiptItem({
    required this.itemName,
    required this.baseCost,
    required this.discount,
    required this.assignedAmounts,
  }) : cost = baseCost - discount;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      itemName: json['item_name'],
      baseCost: json['cost'] * 1.0,
      discount: ((json['discount'] ?? 0) as num).abs() * 1.0,
      assignedAmounts: {},
    );
  }
}
