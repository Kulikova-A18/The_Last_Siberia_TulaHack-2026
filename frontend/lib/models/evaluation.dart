import 'package:hackrank_frontend/models/team.dart';

class EvaluationItem {
  final String criterionId;
  final String title;
  final String? description;
  final double maxScore;
  final double weightPercent;
  final double? rawScore;
  final String? comment;

  EvaluationItem({
    required this.criterionId,
    required this.title,
    this.description,
    required this.maxScore,
    required this.weightPercent,
    this.rawScore,
    this.comment,
  });

  factory EvaluationItem.fromJson(Map<String, dynamic> json) {
    return EvaluationItem(
      criterionId: json['criterion_id'],
      title: json['title'],
      description: json['description'],
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
  final Team team;
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
      team: Team.fromJson(json['team']),
      criteria: (json['criteria'] as List)
          .map((e) => EvaluationItem.fromJson(e))
          .toList(),
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
