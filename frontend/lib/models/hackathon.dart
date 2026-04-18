class Hackathon {
  final String id;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final bool resultsPublished;
  final bool resultsFrozen;
  final DateTime createdAt;
  final DateTime updatedAt;

  Hackathon({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.resultsPublished,
    required this.resultsFrozen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Hackathon.fromJson(Map<String, dynamic> json) {
    return Hackathon(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      status: json['status'],
      resultsPublished: json['results_published'] ?? false,
      resultsFrozen: json['results_frozen'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Deadline {
  final String id;
  final String title;
  final DateTime deadlineAt;

  Deadline({required this.id, required this.title, required this.deadlineAt});

  factory Deadline.fromJson(Map<String, dynamic> json) {
    return Deadline(
      id: json['id'],
      title: json['title'],
      deadlineAt: DateTime.parse(json['deadline_at']),
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
      teamsTotal: json['teams_total'] ?? 0,
      expertsTotal: json['experts_total'] ?? 0,
      criteriaTotal: json['criteria_total'] ?? 0,
      evaluationsSubmitted: json['evaluations_submitted'] ?? 0,
      evaluationsDraft: json['evaluations_draft'] ?? 0,
      evaluationsTotalExpected: json['evaluations_total_expected'] ?? 0,
      leaderboardTop: (json['leaderboard_top'] as List?)
              ?.map((e) => LeaderboardEntry.fromJson(e))
              .toList() ??
          [],
      expertsProgress: (json['experts_progress'] as List?)
              ?.map((e) => ExpertProgress.fromJson(e))
              .toList() ??
          [],
      nextDeadline: json['next_deadline'] != null
          ? Deadline.fromJson(json['next_deadline'])
          : null,
    );
  }
}

class TimerResponse {
  final DateTime serverTime;
  final String hackathonStatus;
  final String currentPhase;
  final Deadline? nextDeadline;
  final int? secondsRemaining;

  TimerResponse({
    required this.serverTime,
    required this.hackathonStatus,
    required this.currentPhase,
    this.nextDeadline,
    this.secondsRemaining,
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

class Assignment {
  final String id;
  final String hackathonId;
  final String expertUserId;
  final String teamId;
  final DateTime assignedAt;

  Assignment({
    required this.id,
    required this.hackathonId,
    required this.expertUserId,
    required this.teamId,
    required this.assignedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      hackathonId: json['hackathon_id'],
      expertUserId: json['expert_user_id'],
      teamId: json['team_id'],
      assignedAt: DateTime.parse(json['assigned_at']),
    );
  }
}

class LeaderboardResponse {
  final bool published;
  final bool frozen;
  final List<LeaderboardEntry> items;
  final DateTime? updatedAt;

  LeaderboardResponse({
    required this.published,
    required this.frozen,
    required this.items,
    this.updatedAt,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      published: json['published'] ?? false,
      frozen: json['frozen'] ?? false,
      items: (json['items'] as List?)
              ?.map((e) => LeaderboardEntry.fromJson(e))
              .toList() ??
          [],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}

class PublicLeaderboardItem {
  final int place;
  final String teamName;
  final double finalScore;

  PublicLeaderboardItem(
      {required this.place, required this.teamName, required this.finalScore});

  factory PublicLeaderboardItem.fromJson(Map<String, dynamic> json) {
    return PublicLeaderboardItem(
      place: json['place'],
      teamName: json['team_name'],
      finalScore: (json['final_score'] as num).toDouble(),
    );
  }
}

class PublicLeaderboardResponse {
  final bool published;
  final List<PublicLeaderboardItem> items;
  final DateTime updatedAt;

  PublicLeaderboardResponse({
    required this.published,
    required this.items,
    required this.updatedAt,
  });

  factory PublicLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return PublicLeaderboardResponse(
      published: json['published'] ?? false,
      items: (json['items'] as List?)
              ?.map((e) => PublicLeaderboardItem.fromJson(e))
              .toList() ??
          [],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class PublicTimerResponse {
  final String hackathonStatus;
  final String currentPhase;
  final String? nextDeadlineTitle;
  final DateTime? nextDeadlineAt;
  final int? secondsRemaining;

  PublicTimerResponse({
    required this.hackathonStatus,
    required this.currentPhase,
    this.nextDeadlineTitle,
    this.nextDeadlineAt,
    this.secondsRemaining,
  });

  factory PublicTimerResponse.fromJson(Map<String, dynamic> json) {
    return PublicTimerResponse(
      hackathonStatus: json['hackathon_status'],
      currentPhase: json['current_phase'],
      nextDeadlineTitle: json['next_deadline_title'],
      nextDeadlineAt: json['next_deadline_at'] != null
          ? DateTime.parse(json['next_deadline_at'])
          : null,
      secondsRemaining: json['seconds_remaining'],
    );
  }
}
