import 'team.dart';

class EvaluationItem {
  final String criterionId;
  final String title;
  final double maxScore;
  final double weightPercent;
  final double? rawScore;
  final String? comment;

  EvaluationItem({
    required this.criterionId,
    required this.title,
    required this.maxScore,
    required this.weightPercent,
    this.rawScore,
    this.comment,
  });

  factory EvaluationItem.fromJson(Map<String, dynamic> json) {
    return EvaluationItem(
      criterionId: json['criterion_id'],
      title: json['title'],
      maxScore: (json['max_score'] as num).toDouble(),
      weightPercent: (json['weight_percent'] as num).toDouble(),
      rawScore: (json['raw_score'] as num?)?.toDouble(),
      comment: json['comment'],
    );
  }
}

class MyEvaluation {
  final String? evaluationId;
  final String status;
  final Map<String, dynamic> team;
  final List<EvaluationItem> criteria;
  final String? overallComment;

  MyEvaluation({
    this.evaluationId,
    required this.status,
    required this.team,
    required this.criteria,
    this.overallComment,
  });

  factory MyEvaluation.fromJson(Map<String, dynamic> json) {
    return MyEvaluation(
      evaluationId: json['evaluation_id'],
      status: json['status'],
      team: json['team'] as Map<String, dynamic>? ?? {},
      criteria: (json['criteria'] as List?)
              ?.map((e) => EvaluationItem.fromJson(e))
              .toList() ??
          [],
      overallComment: json['overall_comment'],
    );
  }
}

class AssignedTeam {
  final String teamId;
  final String teamName;
  final String projectTitle;
  final String evaluationStatus;
  final DateTime? submittedAt;

  AssignedTeam({
    required this.teamId,
    required this.teamName,
    required this.projectTitle,
    required this.evaluationStatus,
    this.submittedAt,
  });

  factory AssignedTeam.fromJson(Map<String, dynamic> json) {
    return AssignedTeam(
      teamId: json['team_id'],
      teamName: json['team_name'],
      projectTitle: json['project_title'],
      evaluationStatus: json['evaluation_status'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
    );
  }
}

class AssignedTeamListResponse {
  final List<AssignedTeam> items;
  final int page;
  final int pageSize;
  final int total;

  AssignedTeamListResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory AssignedTeamListResponse.fromJson(Map<String, dynamic> json) {
    return AssignedTeamListResponse(
      items: (json['items'] as List?)
              ?.map((e) => AssignedTeam.fromJson(e))
              .toList() ??
          [],
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      total: json['total'] ?? 0,
    );
  }
}
