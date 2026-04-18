class Team {
  final String id;
  final String name;
  final String captainName;
  final String? contactEmail;
  final String? contactPhone;
  final String projectTitle;
  final String? description;
  final int membersCount;
  final String evaluationStatus;
  final double? finalScore;
  final int? place;

  Team({
    required this.id,
    required this.name,
    required this.captainName,
    this.contactEmail,
    this.contactPhone,
    required this.projectTitle,
    this.description,
    required this.membersCount,
    required this.evaluationStatus,
    this.finalScore,
    this.place,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      captainName: json['captain_name'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      projectTitle: json['project_title'],
      description: json['description'],
      membersCount: json['members_count'] ?? 0,
      evaluationStatus: json['evaluation_status'] ?? 'not_started',
      finalScore: (json['final_score'] as num?)?.toDouble(),
      place: json['place'],
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
