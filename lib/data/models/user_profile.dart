import 'dart:convert';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String ownerName;
  final String companyName;
  final String phone;
  final String email;
  final String businessType;
  final String currency;
  final String fiscalYear;

  const UserProfile({
    this.ownerName = 'Business Owner',
    this.companyName = 'Accounting Myanmar Business',
    this.phone = '09-123456789',
    this.email = 'business@accountingmyanmar.com',
    this.businessType = 'Trading & Services',
    this.currency = 'MMK (Ks)',
    this.fiscalYear = '2026-2027',
  });

  UserProfile copyWith({
    String? ownerName,
    String? companyName,
    String? phone,
    String? email,
    String? businessType,
    String? currency,
    String? fiscalYear,
  }) {
    return UserProfile(
      ownerName: ownerName ?? this.ownerName,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      businessType: businessType ?? this.businessType,
      currency: currency ?? this.currency,
      fiscalYear: fiscalYear ?? this.fiscalYear,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerName': ownerName,
      'companyName': companyName,
      'phone': phone,
      'email': email,
      'businessType': businessType,
      'currency': currency,
      'fiscalYear': fiscalYear,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      ownerName: map['ownerName'] as String? ?? 'Business Owner',
      companyName: map['companyName'] as String? ?? 'Accounting Myanmar Business',
      phone: map['phone'] as String? ?? '09-123456789',
      email: map['email'] as String? ?? 'business@accountingmyanmar.com',
      businessType: map['businessType'] as String? ?? 'Trading & Services',
      currency: map['currency'] as String? ?? 'MMK (Ks)',
      fiscalYear: map['fiscalYear'] as String? ?? '2026-2027',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
    ownerName,
    companyName,
    phone,
    email,
    businessType,
    currency,
    fiscalYear,
  ];
}
