import 'package:dio/dio.dart';
import 'package:hackrank_frontend/models/role.dart';
import 'api_client.dart';
import '../../models/user.dart';
import '../../models/hackathon.dart';
import '../../models/team.dart';
import '../../models/criterion.dart';
import '../../models/evaluation.dart';

// Добавляем недостающие модели прямо в этот файл
class TeamResultDetail {
  final String teamId;
  final String teamName;
  final int? place;
  final double finalScore;
  final List<CriterionBreakdown> criteriaBreakdown;
  final int expertsCount;
  final String status;
  final bool published;

  TeamResultDetail({
    required this.teamId,
    required this.teamName,
    this.place,
    required this.finalScore,
    required this.criteriaBreakdown,
    required this.expertsCount,
    required this.status,
    required this.published,
  });

  factory TeamResultDetail.fromJson(Map<String, dynamic> json) {
    return TeamResultDetail(
      teamId: json['team_id'],
      teamName: json['team_name'],
      place: json['place'],
      finalScore: (json['final_score'] as num).toDouble(),
      criteriaBreakdown: (json['criteria_breakdown'] as List)
          .map((e) => CriterionBreakdown.fromJson(e))
          .toList(),
      expertsCount: json['experts_count'],
      status: json['status'],
      published: json['published'] ?? false,
    );
  }
}

class CriterionBreakdown {
  final String criterionId;
  final String title;
  final double weightPercent;
  final double maxScore;
  final double avgRawScore;
  final double weightedScore;

  CriterionBreakdown({
    required this.criterionId,
    required this.title,
    required this.weightPercent,
    required this.maxScore,
    required this.avgRawScore,
    required this.weightedScore,
  });

  factory CriterionBreakdown.fromJson(Map<String, dynamic> json) {
    return CriterionBreakdown(
      criterionId: json['criterion_id'],
      title: json['title'],
      weightPercent: (json['weight_percent'] as num).toDouble(),
      maxScore: (json['max_score'] as num).toDouble(),
      avgRawScore: (json['avg_raw_score'] as num).toDouble(),
      weightedScore: (json['weighted_score'] as num).toDouble(),
    );
  }
}

class WinnersResponse {
  final List<WinnerItem> items;
  final int totalTeams;

  WinnersResponse({required this.items, required this.totalTeams});

  factory WinnersResponse.fromJson(Map<String, dynamic> json) {
    return WinnersResponse(
      items:
          (json['items'] as List).map((e) => WinnerItem.fromJson(e)).toList(),
      totalTeams: json['total_teams'],
    );
  }
}

class WinnerItem {
  final int place;
  final String teamId;
  final String teamName;
  final double finalScore;
  final String projectTitle;

  WinnerItem({
    required this.place,
    required this.teamId,
    required this.teamName,
    required this.finalScore,
    required this.projectTitle,
  });

  factory WinnerItem.fromJson(Map<String, dynamic> json) {
    return WinnerItem(
      place: json['place'],
      teamId: json['team_id'],
      teamName: json['team_name'],
      finalScore: (json['final_score'] as num).toDouble(),
      projectTitle: json['project_title'],
    );
  }
}

class ExpertDashboard {
  final int assignedTeamsCount;
  final int evaluatedCount;
  final int remainingCount;
  final Deadline? nextDeadline;

  ExpertDashboard({
    required this.assignedTeamsCount,
    required this.evaluatedCount,
    required this.remainingCount,
    this.nextDeadline,
  });

  factory ExpertDashboard.fromJson(Map<String, dynamic> json) {
    return ExpertDashboard(
      assignedTeamsCount: json['assigned_teams_count'],
      evaluatedCount: json['evaluated_count'],
      remainingCount: json['remaining_count'],
      nextDeadline: json['next_deadline'] != null
          ? Deadline.fromJson(json['next_deadline'])
          : null,
    );
  }
}

class PublicWinnersResponse {
  final List<PublicLeaderboardItem> top3;
  final int totalTeams;

  PublicWinnersResponse({required this.top3, required this.totalTeams});

  factory PublicWinnersResponse.fromJson(Map<String, dynamic> json) {
    return PublicWinnersResponse(
      top3: (json['top_3'] as List)
          .map((e) => PublicLeaderboardItem.fromJson(e))
          .toList(),
      totalTeams: json['total_teams'],
    );
  }
}

class AuditLogListResponse {
  final List<AuditLog> items;
  final int page;
  final int pageSize;
  final int total;

  AuditLogListResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory AuditLogListResponse.fromJson(Map<String, dynamic> json) {
    return AuditLogListResponse(
      items: (json['items'] as List).map((e) => AuditLog.fromJson(e)).toList(),
      page: json['page'],
      pageSize: json['page_size'],
      total: json['total'],
    );
  }
}

class AuditLog {
  final int id;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic> payload;
  final Map<String, dynamic>? performedBy;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    required this.payload,
    this.performedBy,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      action: json['action'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      payload: json['payload'] ?? {},
      performedBy: json['performed_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

// Основной класс ApiService
class ApiService {
  final ApiClient _client;

  ApiService(this._client);

  // ========== AUTH ==========
  Future<AuthResponse> login(String login, String password) async {
    final response = await _client
        .post('/auth/login', data: {'login': login, 'password': password});
    return AuthResponse.fromJson(response.data);
  }

  Future<void> logout(String refreshToken) async {
    await _client.post('/auth/logout', data: {'refresh_token': refreshToken});
  }

  Future<User> getMe() async {
    final response = await _client.get('/auth/me');
    return User.fromJson(response.data['user']);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _client.post('/auth/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword});
  }

  // ========== HACKATHONS ==========
  Future<Hackathon?> getActiveHackathon() async {
    try {
      final response = await _client.get('/hackathons/active');
      return Hackathon.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<List<Hackathon>> getHackathons() async {
    final response = await _client.get('/hackathons/');
    return (response.data as List).map((e) => Hackathon.fromJson(e)).toList();
  }

  Future<Hackathon> createHackathon(Map<String, dynamic> data) async {
    final response = await _client.post('/hackathons/', data: data);
    return Hackathon.fromJson(response.data);
  }

  Future<Hackathon> updateHackathon(
      String id, Map<String, dynamic> data) async {
    final response = await _client.patch('/hackathons/$id', data: data);
    return Hackathon.fromJson(response.data);
  }

  Future<void> startHackathon(String id) async {
    await _client.post('/hackathons/$id/start');
  }

  Future<void> finishHackathon(String id) async {
    await _client.post('/hackathons/$id/finish');
  }

  // ========== USERS ==========
  Future<UserListResponse> getUsers(
      {int page = 1,
      int pageSize = 20,
      String? role,
      String? search,
      bool? isActive}) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (role != null) query['role'] = role;
    if (search != null) query['search'] = search;
    if (isActive != null) query['is_active'] = isActive;
    final response = await _client.get('/users/', queryParameters: query);
    return UserListResponse.fromJson(response.data);
  }

  Future<User> createUser(Map<String, dynamic> data) async {
    final response = await _client.post('/users/', data: data);
    return User.fromJson(response.data);
  }

  Future<User> updateUser(String id, Map<String, dynamic> data) async {
    final response = await _client.patch('/users/$id', data: data);
    return User.fromJson(response.data);
  }

  Future<void> resetUserPassword(String id, String newPassword) async {
    await _client
        .post('/users/$id/reset-password', data: {'new_password': newPassword});
  }

  // ========== ROLES ==========
  Future<List<Role>> getRoles() async {
    final response = await _client.get('/roles/');
    return (response.data as List).map((e) => Role.fromJson(e)).toList();
  }

  // ========== TEAMS ==========
  Future<TeamListResponse> getTeams(String hackathonId,
      {int page = 1, int pageSize = 20, String? search}) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (search != null) query['search'] = search;
    final response = await _client.get('/hackathons/$hackathonId/teams',
        queryParameters: query);
    return TeamListResponse.fromJson(response.data);
  }

  Future<Team> createTeam(String hackathonId, Map<String, dynamic> data) async {
    final response =
        await _client.post('/hackathons/$hackathonId/teams', data: data);
    return Team.fromJson(response.data);
  }

  Future<TeamDetail> getTeam(String hackathonId, String teamId) async {
    final response =
        await _client.get('/hackathons/$hackathonId/teams/$teamId');
    return TeamDetail.fromJson(response.data);
  }

  Future<Team> updateTeam(
      String hackathonId, String teamId, Map<String, dynamic> data) async {
    final response = await _client
        .patch('/hackathons/$hackathonId/teams/$teamId', data: data);
    return Team.fromJson(response.data);
  }

  Future<void> deleteTeam(String hackathonId, String teamId) async {
    await _client.delete('/hackathons/$hackathonId/teams/$teamId');
  }

  Future<TeamMember> addTeamMember(
      String hackathonId, String teamId, Map<String, dynamic> data) async {
    final response = await _client
        .post('/hackathons/$hackathonId/teams/$teamId/members', data: data);
    return TeamMember.fromJson(response.data);
  }

  Future<TeamMember> updateTeamMember(String hackathonId, String teamId,
      String memberId, Map<String, dynamic> data) async {
    final response = await _client.patch(
        '/hackathons/$hackathonId/teams/$teamId/members/$memberId',
        data: data);
    return TeamMember.fromJson(response.data);
  }

  Future<void> deleteTeamMember(
      String hackathonId, String teamId, String memberId) async {
    await _client
        .delete('/hackathons/$hackathonId/teams/$teamId/members/$memberId');
  }

  // ========== MY TEAM ==========
  Future<TeamDetail> getMyTeam(String hackathonId) async {
    final response = await _client.get('/hackathons/$hackathonId/my/team');
    return TeamDetail.fromJson(response.data);
  }

  Future<TeamResultDetail> getMyTeamResult(String hackathonId) async {
    final response =
        await _client.get('/hackathons/$hackathonId/my/team/result');
    return TeamResultDetail.fromJson(response.data);
  }

  // ========== CRITERIA ==========
  Future<CriteriaListResponse> getCriteria(String hackathonId) async {
    final response = await _client.get('/hackathons/$hackathonId/criteria');
    return CriteriaListResponse.fromJson(response.data);
  }

  Future<Criterion> createCriterion(
      String hackathonId, Map<String, dynamic> data) async {
    final response =
        await _client.post('/hackathons/$hackathonId/criteria', data: data);
    return Criterion.fromJson(response.data);
  }

  Future<Criterion> updateCriterion(
      String hackathonId, String criterionId, Map<String, dynamic> data) async {
    final response = await _client
        .patch('/hackathons/$hackathonId/criteria/$criterionId', data: data);
    return Criterion.fromJson(response.data);
  }

  Future<void> deleteCriterion(String hackathonId, String criterionId) async {
    await _client.delete('/hackathons/$hackathonId/criteria/$criterionId');
  }

  Future<void> reorderCriteria(
      String hackathonId, List<Map<String, dynamic>> items) async {
    await _client.post('/hackathons/$hackathonId/criteria/reorder',
        data: {'items': items});
  }

  // ========== ASSIGNMENTS ==========
  Future<List<Assignment>> getAssignments(String hackathonId,
      {String? expertId, String? teamId}) async {
    final query = <String, dynamic>{};
    if (expertId != null) query['expert_id'] = expertId;
    if (teamId != null) query['team_id'] = teamId;
    final response = await _client.get('/hackathons/$hackathonId/assignments',
        queryParameters: query);
    return (response.data as List).map((e) => Assignment.fromJson(e)).toList();
  }

  Future<Assignment> createAssignment(
      String hackathonId, String expertUserId, String teamId) async {
    final response = await _client.post('/hackathons/$hackathonId/assignments',
        data: {'expert_user_id': expertUserId, 'team_id': teamId});
    return Assignment.fromJson(response.data);
  }

  Future<List<Assignment>> bulkCreateAssignments(
      String hackathonId, List<Map<String, dynamic>> items) async {
    final response = await _client.post(
        '/hackathons/$hackathonId/assignments/bulk',
        data: {'items': items});
    return (response.data as List).map((e) => Assignment.fromJson(e)).toList();
  }

  Future<void> deleteAssignment(String hackathonId, String assignmentId) async {
    await _client.delete('/hackathons/$hackathonId/assignments/$assignmentId');
  }

  // ========== EVALUATIONS ==========
  Future<AssignedTeamListResponse> getMyAssignedTeams(String hackathonId,
      {int page = 1, int pageSize = 20, String? status}) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (status != null) query['status'] = status;
    final response = await _client.get(
        '/hackathons/$hackathonId/my/assigned-teams',
        queryParameters: query);
    return AssignedTeamListResponse.fromJson(response.data);
  }

  Future<MyEvaluation> getMyEvaluation(
      String hackathonId, String teamId) async {
    final response = await _client
        .get('/hackathons/$hackathonId/teams/$teamId/my-evaluation');
    return MyEvaluation.fromJson(response.data);
  }

  Future<Map<String, dynamic>> saveEvaluationDraft(
      String hackathonId, String teamId, Map<String, dynamic> data) async {
    final response = await _client.put(
        '/hackathons/$hackathonId/teams/$teamId/my-evaluation/draft',
        data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> submitEvaluation(
      String hackathonId, String teamId, Map<String, dynamic> data) async {
    final response = await _client.post(
        '/hackathons/$hackathonId/teams/$teamId/my-evaluation/submit',
        data: data);
    return response.data;
  }

  // ========== RESULTS ==========
  Future<LeaderboardResponse> getLeaderboard(String hackathonId,
      {bool publishedOnly = false}) async {
    final response = await _client.get(
        '/hackathons/$hackathonId/results/leaderboard',
        queryParameters: {'published_only': publishedOnly});
    return LeaderboardResponse.fromJson(response.data);
  }

  Future<TeamResultDetail> getTeamResult(
      String hackathonId, String teamId) async {
    final response =
        await _client.get('/hackathons/$hackathonId/results/teams/$teamId');
    return TeamResultDetail.fromJson(response.data);
  }

  Future<void> recalculateResults(String hackathonId) async {
    await _client.post('/hackathons/$hackathonId/results/recalculate');
  }

  Future<void> publishResults(String hackathonId) async {
    await _client.post('/hackathons/$hackathonId/results/publish');
  }

  Future<void> unpublishResults(String hackathonId) async {
    await _client.post('/hackathons/$hackathonId/results/unpublish');
  }

  Future<void> freezeResults(String hackathonId) async {
    await _client.post('/hackathons/$hackathonId/results/freeze');
  }

  Future<WinnersResponse> getWinners(String hackathonId, {int top = 3}) async {
    final response = await _client.get(
        '/hackathons/$hackathonId/results/winners',
        queryParameters: {'top': top});
    return WinnersResponse.fromJson(response.data);
  }

  Future<Response> exportResults(String hackathonId,
      {String format = 'csv'}) async {
    return await _client.get('/hackathons/$hackathonId/results/export',
        queryParameters: {'format': format});
  }

  // ========== DASHBOARDS ==========
  Future<AdminDashboard> getAdminDashboard(String hackathonId) async {
    final response =
        await _client.get('/hackathons/$hackathonId/dashboard/admin');
    return AdminDashboard.fromJson(response.data);
  }

  Future<ExpertDashboard> getExpertDashboard(String hackathonId) async {
    final response =
        await _client.get('/hackathons/$hackathonId/dashboard/expert');
    return ExpertDashboard.fromJson(response.data);
  }

  // ========== DEADLINES & TIMER ==========
  Future<List<Deadline>> getDeadlines(String hackathonId) async {
    final response = await _client.get('/hackathons/$hackathonId/deadlines');
    return (response.data as List).map((e) => Deadline.fromJson(e)).toList();
  }

  Future<Deadline> createDeadline(
      String hackathonId, Map<String, dynamic> data) async {
    final response =
        await _client.post('/hackathons/$hackathonId/deadlines', data: data);
    return Deadline.fromJson(response.data);
  }

  Future<Deadline> updateDeadline(
      String hackathonId, String deadlineId, Map<String, dynamic> data) async {
    final response = await _client
        .patch('/hackathons/$hackathonId/deadlines/$deadlineId', data: data);
    return Deadline.fromJson(response.data);
  }

  Future<void> deleteDeadline(String hackathonId, String deadlineId) async {
    await _client.delete('/hackathons/$hackathonId/deadlines/$deadlineId');
  }

  Future<TimerResponse> getTimer(String hackathonId) async {
    final response = await _client.get('/hackathons/$hackathonId/timer');
    return TimerResponse.fromJson(response.data);
  }

  // ========== PUBLIC ==========
  Future<PublicLeaderboardResponse> getPublicLeaderboard(
      String hackathonId) async {
    final response =
        await _client.get('/public/hackathons/$hackathonId/leaderboard');
    return PublicLeaderboardResponse.fromJson(response.data);
  }

  Future<PublicTimerResponse> getPublicTimer(String hackathonId) async {
    final response = await _client.get('/public/hackathons/$hackathonId/timer');
    return PublicTimerResponse.fromJson(response.data);
  }

  Future<PublicWinnersResponse> getPublicWinners(String hackathonId) async {
    final response =
        await _client.get('/public/hackathons/$hackathonId/winners');
    return PublicWinnersResponse.fromJson(response.data);
  }

  // ========== AUDIT ==========
  Future<AuditLogListResponse> getAuditLogs(String hackathonId,
      {int page = 1,
      int pageSize = 50,
      String? entityType,
      String? userId}) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (entityType != null) query['entity_type'] = entityType;
    if (userId != null) query['user_id'] = userId;
    final response = await _client.get('/hackathons/$hackathonId/audit-logs',
        queryParameters: query);
    return AuditLogListResponse.fromJson(response.data);
  }
}
