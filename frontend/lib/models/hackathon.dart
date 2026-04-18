class Hackathon {
  final String id;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final String status;

  Hackathon({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    required this.endAt,
    required this.status,
  });

  factory Hackathon.fromJson(Map<String, dynamic> json) {
    return Hackathon(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      status: json['status'],
    );
  }
}

class AdminDashboard {
  final int teamsTotal;
  final int expertsTotal;
  final int criteriaTotal;
  final int evaluationsSubmitted;
  final int evaluationsDraft;
  final int evaluationsTotalExpected;
  final List<LeaderboardEntry> leaderboardTop;
  final List<ExpertProgress> expertsProgress;
  final Deadline? nextDeadline;

  AdminDashboard({
    required this.teamsTotal,
    required this.expertsTotal,
    required this.criteriaTotal,
    required this.evaluationsSubmitted,
    required this.evaluationsDraft,
    required this.evaluationsTotalExpected,
    required this.leaderboardTop,
    required this.expertsProgress,
    this.nextDeadline,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      teamsTotal: json['teams_total'],
      expertsTotal: json['experts_total'],
      criteriaTotal: json['criteria_total'],
      evaluationsSubmitted: json['evaluations_submitted'],
      evaluationsDraft: json['evaluations_draft'],
      evaluationsTotalExpected: json['evaluations_total_expected'],
      leaderboardTop: (json['leaderboard_top'] as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList(),
      expertsProgress: (json['experts_progress'] as List)
          .map((e) => ExpertProgress.fromJson(e))
          .toList(),
      nextDeadline: json['next_deadline'] != null
          ? Deadline.fromJson(json['next_deadline'])
          : null,
    );
  }
}

class LeaderboardEntry {
  final int place;
  final String teamId;
  final String teamName;
  final double finalScore;

  LeaderboardEntry({
    required this.place,
    required this.teamId,
    required this.teamName,
    required this.finalScore,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      place: json['place'],
      teamId: json['team_id'],
      teamName: json['team_name'],
      finalScore: (json['final_score'] as num).toDouble(),
    );
  }
}

class ExpertProgress {
  final String expertId;
  final String expertName;
  final int submitted;
  final int totalAssigned;

  ExpertProgress({
    required this.expertId,
    required this.expertName,
    required this.submitted,
    required this.totalAssigned,
  });

  factory ExpertProgress.fromJson(Map<String, dynamic> json) {
    return ExpertProgress(
      expertId: json['expert_id'],
      expertName: json['expert_name'],
      submitted: json['submitted'],
      totalAssigned: json['total_assigned'],
    );
  }
}

class Deadline {
  final String id;
  final String title;
  final DateTime deadlineAt;

  Deadline({
    required this.id,
    required this.title,
    required this.deadlineAt,
  });

  factory Deadline.fromJson(Map<String, dynamic> json) {
    return Deadline(
      id: json['id'],
      title: json['title'],
      deadlineAt: DateTime.parse(json['deadline_at']),
    );
  }
}

class TimerResponse {
  final DateTime serverTime;
  final String hackathonStatus;
  final String currentPhase;
  final Deadline? nextDeadline;
  final int secondsRemaining;

  TimerResponse({
    required this.serverTime,
    required this.hackathonStatus,
    required this.currentPhase,
    this.nextDeadline,
    required this.secondsRemaining,
  });

  factory TimerResponse.fromJson(Map<String, dynamic> json) {
    return TimerResponse(
      serverTime: DateTime.parse(json['server_time']),
      hackathonStatus: json['hackathon_status'],
      currentPhase: json['current_phase'],
      nextDeadline: json['next_deadline'] != null
          ? Deadline.fromJson(json['next_deadline'])
          : null,
      secondsRemaining: json['seconds_remaining'],
    );
  }
}
