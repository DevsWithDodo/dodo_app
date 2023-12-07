import 'package:equatable/equatable.dart';

class Group extends Equatable {
  final String currency;
  final String name;
  final int id;
  const Group({
    required this.name,
    required this.id,
    required this.currency,
  });

  Group.fromJson(Map<String, dynamic> json)
      : currency = json["currency"],
        name = json["name"],
        id = json["id"];

  Map<String, dynamic> toJson() => {
    "currency": currency,
    "name": name,
    "id": id,
  };

  @override
  List<Object> get props => [id, name, currency];
}