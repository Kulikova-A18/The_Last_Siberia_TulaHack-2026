class Team {
  final String id;
  final String hackathonId;
  final String name;
  final String captainName;
  final String? contactEmail;
  final String? contactPhone;
  final String projectTitle;
  final String? description;
  final int membersCount;
  final String? evaluationStatus;
  final double? finalScore;
  final int? place;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.hackathonId,
    required this.name,
    required this.captainName,
    this.contactEmail,
    this.contactPhone,
    required this.projectTitle,
    this.description,
    required this.membersCount,
    this.evaluationStatus,
    this.finalScore,
    this.place,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      hackathonId: json['hackathon_id'],
      name: json['name'],
      captainName: json['captain_name'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      projectTitle: json['project_title'],
      description: json['description'],
      membersCount: json['members_count'] ?? 0,
      evaluationStatus: json['evaluation_status'],
      finalScore: (json['final_score'] as num?)?.toDouble(),
      place: json['place'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class TeamMember {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? organization;
  final bool isCaptain;

  TeamMember({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.organization,
    required this.isCaptain,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      organization: json['organization'],
      isCaptain: json['is_captain'] ?? false,
    );
  }
}

class TeamDetail {
  final String id;
  final String name;
  final String captainName;
  final String? contactEmail;
  final String? contactPhone;
  final String projectTitle;
  final String? description;
  final List<TeamMember> members;
  final List<Map<String, dynamic>> assignedExperts;
  final String evaluationStatus;
  final double? finalScore;
  final int? place;

  TeamDetail({
    required this.id,
    required this.name,
    required this.captainName,
    this.contactEmail,
    this.contactPhone,
    required this.projectTitle,
    this.description,
    required this.members,
    required this.assignedExperts,
    required this.evaluationStatus,
    this.finalScore,
    this.place,
  });

  factory TeamDetail.fromJson(Map<String, dynamic> json) {
    return TeamDetail(
      id: json['id'],
      name: json['name'],
      captainName: json['captain_name'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      projectTitle: json['project_title'],
      description: json['description'],
      members: (json['members'] as List?)
              ?.map((e) => TeamMember.fromJson(e))
              .toList() ??
          [],
      assignedExperts: (json['assigned_experts'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      evaluationStatus: json['evaluation_status'] ?? 'not_started',
      finalScore: (json['final_score'] as num?)?.toDouble(),
      place: json['place'],
    );
  }
}

class TeamListResponse {
  final List<Team> items;
  final int page;
  final int pageSize;
  final int total;

  TeamListResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory TeamListResponse.fromJson(Map<String, dynamic> json) {
    return TeamListResponse(
      items:
          (json['items'] as List?)?.map((e) => Team.fromJson(e)).toList() ?? [],
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      total: json['total'] ?? 0,
    );
  }
}
