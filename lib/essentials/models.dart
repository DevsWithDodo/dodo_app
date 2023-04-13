import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import '../config.dart';

class Member {
  double? balance;
  String? nickname;
  String? username;
  String? apiToken;
  int? memberId;
  bool? isAdmin;
  double? balanceOriginalCurrency;
  bool? isCustomAmount;
  bool? isGuest;
  Member({
    this.username,
    this.nickname,
    this.balance,
    this.isAdmin,
    this.memberId,
    this.apiToken,
    this.balanceOriginalCurrency,
    this.isCustomAmount,
    this.isGuest,
  });
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      username: json['username'],
      memberId: json['user_id'],
      nickname: json['nickname'],
      balance: json['balance'] * 1.0,
      isAdmin: json['is_admin'] == 1,
      balanceOriginalCurrency: (json['original_balance'] ?? 0) * 1.0,
      isCustomAmount: json['custom_amount'] ?? false,
      isGuest: json['is_guest'] == 1,
    );
  }

  @override
  String toString() {
    return nickname!;
  }

  Map toJson() {
    return {'user_id': memberId};
  }
}

class Group {
  String? groupCurrency;
  String? groupName;
  int? groupId;
  Group({this.groupName, this.groupId, this.groupCurrency});
}

class Reaction {
  String reaction;
  String nickname;
  int userId;
  static const List<String> possibleReactions = [
    '👍',
    '❤',
    '😲',
    '😥',
    '❗',
    '❓'
  ];
  Reaction(
      {required this.reaction, required this.nickname, required this.userId});
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
  DateTime? updatedAt;
  String? buyerUsername, buyerNickname;
  int? buyerId;
  List<Member>? receivers;
  double? totalAmount, totalAmountOriginalCurrency;
  int? purchaseId;
  String? name;
  List<Reaction>? reactions;
  String? originalCurrency;
  Category? category;

  Purchase({
    this.updatedAt,
    this.buyerUsername,
    this.buyerNickname,
    this.buyerId,
    this.receivers,
    this.totalAmount,
    this.totalAmountOriginalCurrency,
    this.purchaseId,
    this.name,
    this.reactions,
    this.originalCurrency,
    this.category,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      purchaseId: json['purchase_id'],
      name: json['name'],
      updatedAt: json['updated_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['updated_at']).toLocal(),
      originalCurrency: json['original_currency'] ?? currentGroupCurrency,
      buyerUsername: json['buyer_username'],
      buyerId: json['buyer_id'],
      buyerNickname: json['buyer_nickname'],
      totalAmount: (json['total_amount'] * 1.0),
      totalAmountOriginalCurrency: (json['original_total_amount'] ?? 0) * 1.0,
      receivers: json['receivers']
          .map<Member>((element) => Member.fromJson(element))
          .toList(),
      reactions: json['reactions']
          .map<Reaction>((reaction) => Reaction.fromJson(reaction))
          .toList(),
      category: Category.fromName(json["category"]),
    );
  }
}

class Payment {
  int? paymentId;
  double? amount, amountOriginalCurrency;
  DateTime? updatedAt;
  String? payerUsername, payerNickname, takerUsername, takerNickname, note;
  int? payerId, takerId;
  List<Reaction>? reactions;
  String? originalCurrency;

  Payment({
    this.paymentId,
    this.amount,
    this.amountOriginalCurrency,
    this.updatedAt,
    this.payerUsername,
    this.payerId,
    this.payerNickname,
    this.takerUsername,
    this.takerId,
    this.takerNickname,
    this.note,
    this.reactions,
    this.originalCurrency,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentId: json['payment_id'],
      amount: (json['amount'] * 1.0),
      updatedAt: json['updated_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['updated_at']).toLocal(),
      payerId: json['payer_id'],
      payerUsername: json['payer_username'],
      payerNickname: json['payer_nickname'],
      takerId: json['taker_id'],
      takerUsername: json['taker_username'],
      takerNickname: json['taker_nickname'],
      note: json['note'],
      originalCurrency: json['original_currency'] ?? currentGroupCurrency,
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
        text: 'groceries'),
    Category(
        type: CategoryType.transport, icon: Icons.train, text: 'transport'),
    Category(
        type: CategoryType.entertainment,
        icon: Icons.movie_filter,
        text: 'entertainment'),
    Category(
        type: CategoryType.shopping,
        icon: Icons.shopping_bag,
        text: 'shopping'),
    Category(
        type: CategoryType.health,
        icon: Icons.health_and_safety,
        text: 'health'),
    Category(type: CategoryType.bills, icon: Icons.house, text: 'bills'),
    Category(type: CategoryType.other, icon: Icons.more_horiz, text: 'other'),
  ];
}

class ShoppingRequest {
  int? requestId;
  String? name;
  String? requesterUsername, requesterNickname;
  int? requesterId;
  DateTime? updatedAt;
  List<Reaction>? reactions;

  ShoppingRequest(
      {this.updatedAt,
      this.requesterId,
      this.requesterUsername,
      this.name,
      this.requestId,
      this.requesterNickname,
      this.reactions});

  factory ShoppingRequest.fromJson(Map<String, dynamic> json) {
    // print(json);
    return ShoppingRequest(
        requestId: json['request_id'],
        requesterId: json['requester_id'],
        requesterUsername: json['requester_username'],
        requesterNickname: json['requester_nickname'],
        name: json['name'],
        updatedAt: DateTime.parse(json['updated_at']).toLocal(),
        reactions: (json['reactions'] ?? [])
            .map<Reaction>((reaction) => Reaction.fromJson(reaction))
            .toList());
  }

  @override
  String toString() {
    return name! + '; ' + updatedAt.toString() + '; ' + reactions!.join(', ');
  }
}
