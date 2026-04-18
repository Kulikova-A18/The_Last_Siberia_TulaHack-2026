import 'package:dio/dio.dart';
import 'storage_service.dart';

/// Базовый API-сервис. Все методы ЗАКОММЕНТИРОВАНЫ для демонстрации.
class ApiService {
  static const String baseUrl = 'http://localhost:8000/api/v1';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  final StorageService _storage = StorageService();

  ApiService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Можно попытаться обновить токен
        }
        return handler.next(e);
      },
    ));
  }

  // ========== AUTH ==========
  /*
  Future<AuthResponse> login(String login, String password) async {
    // POST /auth/login
    // final response = await _dio.post('/auth/login', data: {'login': login, 'password': password});
    // return AuthResponse.fromJson(response.data);
    throw UnimplementedError();
  }
  */

  /*
  Future<User> getMe() async {
    // GET /auth/me
    // final response = await _dio.get('/auth/me');
    // return User.fromJson(response.data);
    throw UnimplementedError();
  }
  */

  /*
  Future<void> logout(String refreshToken) async {
    // POST /auth/logout
    // await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
  }
  */

  // ========== HACKATHONS ==========
  /*
  Future<Hackathon> getActiveHackathon() async {
    // GET /hackathons/active
    // final response = await _dio.get('/hackathons/active');
    // return Hackathon.fromJson(response.data);
    throw UnimplementedError();
  }
  */

  // ========== DASHBOARDS ==========
  /*
  Future<AdminDashboard> getAdminDashboard(String hackathonId) async {
    // GET /hackathons/{hackathonId}/dashboard/admin
    // final response = await _dio.get('/hackathons/$hackathonId/dashboard/admin');
    // return AdminDashboard.fromJson(response.data);
    throw UnimplementedError();
  }
  */

  /*
  Future<Map<String, dynamic>> getExpertDashboard(String hackathonId) async {
    // GET /hackathons/{hackathonId}/dashboard/expert
    // final response = await _dio.get('/hackathons/$hackathonId/dashboard/expert');
    // return response.data;
    throw UnimplementedError();
  }
  */

  // ========== USERS ==========
  /*
  Future<List<User>> getUsers({String? role, bool? isActive}) async {
    // GET /users?role={role}&is_active={isActive}
    // final response = await _dio.get('/users', queryParameters: {'role': role, 'is_active': isActive});
    // return (response.data['items'] as List).map((e) => User.fromJson(e)).toList();
    throw UnimplementedError();
  }
  */

  /*
  Future<User> createUser(Map<String, dynamic> data) async {
    // POST /users
    // final response = await _dio.post('/users', data: data);
    // return User.fromJson(response.data);
    throw UnimplementedError();
  }
  */

  // ========== TEAMS ==========
  /*
  Future<List<Team>> getTeams(String hackathonId) async {
    // GET /hackathons/{hackathonId}/teams
    // final response = await _dio.get('/hackathons/$hackathonId/teams');
    // return (response.data['items'] as List).map((e) => Team.fromJson(e)).toList();
    throw UnimplementedError();
  }
  */

  /*
  Future<Team> createTeam(String hackathonId, Map<String, dynamic> data) async {
    // POST /hackathons/{hackathonId}/teams
    // final response = await _dio.post('/hackathons/$hackathonId/teams', data: data);
    // return Team.fromJson(response.data);
    throw UnimplementedError();
  }
  */

  // ========== CRITERIA ==========
  /*
  Future<CriteriaListResponse> getCriteria(String hackathonId) async {
    // GET /hackathons/{hackathonId}/criteria
    // final response = await _dio.get('/hackathons/$hackathonId/criteria');
    // return CriteriaListResponse.fromJson(response.data);
    throw UnimplementedError();
  }
  */

  /*
  Future<Criterion> createCriterion(String hackathonId, Map<String, dynamic> data) async {
    // POST /hackathons/{hackathonId}/criteria
    // final response = await _dio.post('/hackathons/$hackathonId/criteria', data: data);
    // return Criterion.fromJson(response.data);
    throw UnimplementedError();
  }
  */

  // ========== ASSIGNMENTS ==========
  /*
  Future<List<Map<String, dynamic>>> getAssignments(String hackathonId) async {
    // GET /hackathons/{hackathonId}/assignments
    // final response = await _dio.get('/hackathons/$hackathonId/assignments');
    // return (response.data['items'] as List).map((e) => e as Map<String, dynamic>).toList();
    throw UnimplementedError();
  }
  */

  /*
  Future<void> bulkAssign(String hackathonId, List<Map<String, dynamic>> items) async {
    // POST /hackathons/{hackathonId}/assignments/bulk
    // await _dio.post('/hackathons/$hackathonId/assignments/bulk', data: {'items': items});
  }
  */

  // ========== EVALUATIONS ==========
  /*
  Future<List<AssignedTeam>> getMyAssignedTeams(String hackathonId) async {
    // GET /hackathons/{hackathonId}/my/assigned-teams
    // final response = await _dio.get('/hackathons/$hackathonId/my/assigned-teams');
    // return (response.data['items'] as List).map((e) => AssignedTeam.fromJson(e)).toList();
    throw UnimplementedError();
  }
  */

  /*
  Future<MyEvaluation> getMyEvaluation(String hackathonId, String teamId) async {
    // GET /hackathons/{hackathonId}/teams/{teamId}/my-evaluation
    // final response = await _dio.get('/hackathons/$hackathonId/teams/$teamId/my-evaluation');
    // return MyEvaluation.fromJson(response.data);
    throw UnimplementedError();
  }
  */

  /*
  Future<void> saveDraft(String hackathonId, String teamId, Map<String, dynamic> data) async {
    // PUT /hackathons/{hackathonId}/teams/{teamId}/my-evaluation/draft
    // await _dio.put('/hackathons/$hackathonId/teams/$teamId/my-evaluation/draft', data: data);
  }
  */

  /*
  Future<void> submitEvaluation(String hackathonId, String teamId, Map<String, dynamic> data) async {
    // POST /hackathons/{hackathonId}/teams/{teamId}/my-evaluation/submit
    // await _dio.post('/hackathons/$hackathonId/teams/$teamId/my-evaluation/submit', data: data);
  }
  */

  // ========== RESULTS ==========
  /*
  Future<List<LeaderboardEntry>> getLeaderboard(String hackathonId) async {
    // GET /hackathons/{hackathonId}/results/leaderboard
    // final response = await _dio.get('/hackathons/$hackathonId/results/leaderboard');
    // return (response.data['items'] as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
    throw UnimplementedError();
  }
  */

  /*
  Future<void> publishResults(String hackathonId) async {
    // POST /hackathons/{hackathonId}/results/publish
    // await _dio.post('/hackathons/$hackathonId/results/publish');
  }
  */

  // ========== TIMER ==========
  /*
  Future<TimerResponse> getTimer(String hackathonId) async {
    // GET /hackathons/{hackathonId}/timer
    // final response = await _dio.get('/hackathons/$hackathonId/timer');
    // return TimerResponse.fromJson(response.data);
    throw UnimplementedError();
  }
  */
}
