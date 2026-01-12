import 'package:flutter/material.dart';

class RewardModel {
  final String id;
  final String title;
  final String amount;
  final String code;
  bool isScratched;
  final Color color;
  final IconData icon;
  final String? message;
  final DateTime? assignedAt;
  final List<String> targetIds; // IDs of users who can see this reward (user or couple partners)
  final bool isAssigned; // True if this unique reward has been assigned

  RewardModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.code,
    required this.isScratched,
    required this.color,
    required this.icon,
    this.message,
    this.assignedAt,
    this.targetIds = const [],
    this.isAssigned = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'code': code,
      'isScratched': isScratched,
      'color': color.value, // Store int value
      'iconCode': icon.codePoint, // Store codePoint
      'message': message,
      'assignedAt': assignedAt?.toIso8601String(),
      'targetIds': targetIds,
      'isAssigned': isAssigned,
    };
  }

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      amount: json['amount'] ?? '',
      code: json['code'] ?? '',
      isScratched: json['isScratched'] ?? false,
      color: Color(json['color'] ?? 0xFFE91E63),
      icon: IconData(json['iconCode'] ?? 0xe59c, fontFamily: 'MaterialIcons'),
      message: json['message'],
      assignedAt: json['assignedAt'] != null 
          ? DateTime.tryParse(json['assignedAt']) 
          : null,
      targetIds: List<String>.from(json['targetIds'] ?? []),
      isAssigned: json['isAssigned'] ?? false,
    );
  }
  
  RewardModel copyWith({
    String? id,
    String? title,
    String? amount,
    String? code,
    bool? isScratched,
    Color? color,
    IconData? icon,
    String? message,
    DateTime? assignedAt,
    List<String>? targetIds,
    bool? isAssigned,
  }) {
    return RewardModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      code: code ?? this.code,
      isScratched: isScratched ?? this.isScratched,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      message: message ?? this.message,
      assignedAt: assignedAt ?? this.assignedAt,
      targetIds: targetIds ?? this.targetIds,
      isAssigned: isAssigned ?? this.isAssigned,
    );
  }
}
