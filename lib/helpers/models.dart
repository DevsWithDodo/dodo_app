import 'dart:convert';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:csocsort_szamla/helpers/currencies.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class User {
  String apiToken;
  String username;
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

  User({
    required this.apiToken,
    required this.username,
    required this.id,
    required this.currency,
    required this.userStatus,
    this.group,
    this.groups = const [],
    this.ratedApp = false,
    this.showAds = false,
    this.useGradients = true,
    this.personalisedAds = false,
    this.trialVersion = false,
    this.paymentMethods = const [],
  });
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

class PaymentMethod {
  String name;
  String value;
  bool priority;

  PaymentMethod(
      {required this.name, required this.value, required this.priority});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
        name: json['name'], value: json['value'], priority: json['priority']);
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
      name: this.name,
      value: this.value,
      priority: this.priority,
    );
  }
}

class Member {
  int id;
  String username;
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
    required this.username,
    String? nickname,
    required this.balance,
    this.isAdmin,
    this.apiToken,
    double? balanceOriginalCurrency,
    this.isCustomAmount,
    this.isGuest,
    this.paymentMethods,
  }) {
    this.balanceOriginalCurrency = balanceOriginalCurrency ?? balance;
    this.nickname = nickname ?? username;
  }
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      username: json['username'] ?? json['nickname'],
      id: json['user_id'],
      nickname: json['nickname'],
      balance: json['balance'] * 1.0,
      isAdmin: json['is_admin'] == 1,
      balanceOriginalCurrency:
          (json['original_balance'] ?? json['balance']) * 1.0,
      isCustomAmount: json['custom_amount'] ?? false,
      isGuest: json['is_guest'] == 1,
      paymentMethods: json['payment_details'] != null
          ? (jsonDecode(json['payment_details']) as List)
              .map<PaymentMethod>(
                  (paymentMethod) => PaymentMethod.fromJson(paymentMethod))
              .toList()
          : null,
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
  Group({
    required this.name,
    required this.id,
    required this.currency,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      name: json['group_name'],
      id: json['group_id'],
      currency: Currency.fromCode(json['currency']),
    );
  }
}

class Reaction {
  static const List<String> possibleReactions = [
    '👍',
    '❤',
    '😲',
    '😥',
    '❗',
    '❓'
  ];
  String reaction;
  String nickname;
  int userId;
  Reaction({
    required this.reaction,
    required this.nickname,
    required this.userId,
  });
  factory Reaction.fromJson(Map<String, dynamic> reaction) {
    return Reaction(
        reaction: reaction['reaction'],
        nickname: reaction['user_nickname'],
        userId: reaction['user_id']);
  }
  @override
  String toString() {
    return reaction;
  }
}

class Purchase {
  int id;
  String buyerUsername;
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
    required this.buyerUsername,
    String? buyerNickname,
    required this.receivers,
    required this.totalAmount,
    double? totalAmountOriginalCurrency,
    required this.originalCurrency,
    required this.updatedAt,
    this.reactions,
    this.category,
  }) {
    this.buyerNickname = buyerNickname ?? buyerUsername;
    this.totalAmountOriginalCurrency =
        totalAmountOriginalCurrency ?? totalAmount;
  }

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['purchase_id'],
      name: json['name'],
      updatedAt: json['updated_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['updated_at']).toLocal(),
      originalCurrency: Currency.fromCode(json['original_currency']),
      buyerUsername: json['buyer_username'] ?? json['buyer_nickname'],
      buyerId: json['buyer_id'],
      buyerNickname: json['buyer_nickname'],
      totalAmount: (json['total_amount'] * 1.0),
      totalAmountOriginalCurrency:
          (json['original_total_amount'] ?? json['original_currency']) * 1.0,
      receivers: json['receivers']
          .map<Member>((element) => Member.fromJson(element))
          .toList(),
      reactions: json['reactions']
          .map<Reaction>((reaction) => Reaction.fromJson(reaction))
          .toList(),
      category: Category.fromName(json["category"]),
    );
  }

  factory Purchase.example(String name, double amount, Currency currency, Member buyer, List<Member> receivers, [List<Reaction> reactions = const []]) {
    return Purchase(
      id: 0,
      name: name,
      updatedAt: DateTime.now(),
      originalCurrency: currency,
      buyerUsername: buyer.username,
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
  String payerUsername, payerNickname, takerUsername, takerNickname;
  late String note;
  int payerId, takerId;
  List<Reaction>? reactions;
  Currency originalCurrency;

  Payment({
    required this.id,
    required this.amount,
    double? amountOriginalCurrency,
    required this.payerUsername,
    required this.payerId,
    required this.payerNickname,
    required this.takerUsername,
    required this.takerId,
    required this.takerNickname,
    String? note,
    required this.originalCurrency,
    required this.updatedAt,
    this.reactions,
  }) {
    this.amountOriginalCurrency = amountOriginalCurrency ?? this.amount;
    this.note = note ?? '';
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['payment_id'],
      amount: (json['amount'] * 1.0),
      updatedAt: json['updated_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['updated_at']).toLocal(),
      payerId: json['payer_id'],
      payerUsername: json['payer_username'] ?? json['payer_nickname'],
      payerNickname: json['payer_nickname'],
      takerId: json['taker_id'],
      takerUsername: json['taker_username'] ?? json['taker_nickname'],
      takerNickname: json['taker_nickname'],
      note: json['note'],
      originalCurrency: Currency.fromCode(json['original_currency']),
      amountOriginalCurrency: (json['original_amount'] ?? json['amount']) * 1.0,
      reactions: json['reactions']
          .map<Reaction>((reaction) => Reaction.fromJson(reaction))
          .toList(),
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
    return Category.categories
        .firstWhereOrNull((category) => category.text == categoryName);
  }

  static Category? fromType(CategoryType? type) {
    return Category.categories
        .firstWhereOrNull((category) => category.type == type);
  }

  static List<Category> categories = [
    Category(type: CategoryType.food, icon: Icons.fastfood, text: 'food'),
    Category(
      type: CategoryType.groceries,
      icon: Icons.shopping_basket,
      text: 'groceries',
    ),
    Category(
        type: CategoryType.transport, icon: Icons.train, text: 'transport'),
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          icon == other.icon &&
          text == other.text;
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
      reactions: (json['reactions'] ?? [])
          .map<Reaction>((reaction) => Reaction.fromJson(reaction))
          .toList(),
    );
  }

  ShoppingRequest clone() {
    return ShoppingRequest(
      id: this.id,
      name: this.name,
      requesterId: this.requesterId,
      requesterNickname: this.requesterNickname,
      updatedAt: this.updatedAt,
    );
  }

  @override
  String toString() {
    return name + '; ' + updatedAt.toString() + '; ' + reactions!.join(', ');
  }
}
