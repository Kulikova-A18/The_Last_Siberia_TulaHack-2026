class Criterion {
  final String id;
  final String title;
  final String? description;
  final double maxScore;
  final double weightPercent;
  final int sortOrder;
  final bool isActive;

  Criterion({
    required this.id,
    required this.title,
    this.description,
    required this.maxScore,
    required this.weightPercent,
    required this.sortOrder,
    required this.isActive,
  });

  factory Criterion.fromJson(Map<String, dynamic> json) {
    return Criterion(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      maxScore: (json['max_score'] as num).toDouble(),
      weightPercent: (json['weight_percent'] as num).toDouble(),
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

class CriteriaListResponse {
  final List<Criterion> items;
  final double totalWeight;
  final bool weightsValid;

  CriteriaListResponse({
    required this.items,
    required this.totalWeight,
    required this.weightsValid,
  });

  factory CriteriaListResponse.fromJson(Map<String, dynamic> json) {
    return CriteriaListResponse(
      items: (json['items'] as List?)
              ?.map((e) => Criterion.fromJson(e))
              .toList() ??
          [],
      totalWeight: (json['total_weight'] as num?)?.toDouble() ?? 0.0,
      weightsValid: json['weights_valid'] ?? false,
    );
  }
}
