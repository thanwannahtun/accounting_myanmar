import 'package:equatable/equatable.dart';

class ArticleModel extends Equatable {
  final String id;
  final int order;
  final String titleMm;
  final String titleEn;
  final String subtitleMm;
  final String category;
  final List<String> targetAudience;
  final int readTimeMinutes;
  final String filePath;
  final String icon;
  final String summaryMm;

  const ArticleModel({
    required this.id,
    required this.order,
    required this.titleMm,
    required this.titleEn,
    required this.subtitleMm,
    required this.category,
    required this.targetAudience,
    required this.readTimeMinutes,
    required this.filePath,
    required this.icon,
    required this.summaryMm,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      titleMm: json['titleMm'] as String? ?? '',
      titleEn: json['titleEn'] as String? ?? '',
      subtitleMm: json['subtitleMm'] as String? ?? '',
      category: json['category'] as String? ?? '',
      targetAudience: (json['targetAudience'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      readTimeMinutes: json['readTimeMinutes'] as int? ?? 5,
      filePath: json['filePath'] as String? ?? '',
      icon: json['icon'] as String? ?? 'menu_book_outlined',
      summaryMm: json['summaryMm'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'titleMm': titleMm,
      'titleEn': titleEn,
      'subtitleMm': subtitleMm,
      'category': category,
      'targetAudience': targetAudience,
      'readTimeMinutes': readTimeMinutes,
      'filePath': filePath,
      'icon': icon,
      'summaryMm': summaryMm,
    };
  }

  @override
  List<Object?> get props => [
        id,
        order,
        titleMm,
        titleEn,
        subtitleMm,
        category,
        targetAudience,
        readTimeMinutes,
        filePath,
        icon,
        summaryMm,
      ];
}
