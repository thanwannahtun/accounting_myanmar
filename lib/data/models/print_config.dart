import 'dart:convert';
import 'package:equatable/equatable.dart';

class PrintConfig extends Equatable {
  final String companyName;
  final String title;
  final String slogan;
  final String headerNote;
  final String footerNote;
  final String paperFormat; // 'A4', '80mm', '58mm'
  final bool showSignatures;
  final String currencySymbol;

  const PrintConfig({
    this.companyName = 'Accounting Myanmar Enterprise',
    this.title = 'Financial & Accounting Report',
    this.slogan = 'Precision Bookkeeping & Business Growth',
    this.headerNote = 'Official Accounting Statement - Confidential',
    this.footerNote = 'Generated via Accounting Myanmar App. All Rights Reserved.',
    this.paperFormat = 'A4',
    this.showSignatures = true,
    this.currencySymbol = 'Ks',
  });

  PrintConfig copyWith({
    String? companyName,
    String? title,
    String? slogan,
    String? headerNote,
    String? footerNote,
    String? paperFormat,
    bool? showSignatures,
    String? currencySymbol,
  }) {
    return PrintConfig(
      companyName: companyName ?? this.companyName,
      title: title ?? this.title,
      slogan: slogan ?? this.slogan,
      headerNote: headerNote ?? this.headerNote,
      footerNote: footerNote ?? this.footerNote,
      paperFormat: paperFormat ?? this.paperFormat,
      showSignatures: showSignatures ?? this.showSignatures,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'title': title,
      'slogan': slogan,
      'headerNote': headerNote,
      'footerNote': footerNote,
      'paperFormat': paperFormat,
      'showSignatures': showSignatures,
      'currencySymbol': currencySymbol,
    };
  }

  factory PrintConfig.fromMap(Map<String, dynamic> map) {
    return PrintConfig(
      companyName: map['companyName'] as String? ?? 'Accounting Myanmar Enterprise',
      title: map['title'] as String? ?? 'Financial & Accounting Report',
      slogan: map['slogan'] as String? ?? 'Precision Bookkeeping & Business Growth',
      headerNote: map['headerNote'] as String? ?? 'Official Accounting Statement - Confidential',
      footerNote: map['footerNote'] as String? ?? 'Generated via Accounting Myanmar App. All Rights Reserved.',
      paperFormat: map['paperFormat'] as String? ?? 'A4',
      showSignatures: map['showSignatures'] as bool? ?? true,
      currencySymbol: map['currencySymbol'] as String? ?? 'Ks',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PrintConfig.fromJson(String source) =>
      PrintConfig.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
    companyName,
    title,
    slogan,
    headerNote,
    footerNote,
    paperFormat,
    showSignatures,
    currencySymbol,
  ];
}
