import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hackathon.dart';
import '../models/team.dart';
import '../models/criterion.dart';
import '../models/evaluation.dart';
import '../services/api/api_service.dart';
import 'auth_provider.dart';

final activeHackathonProvider = FutureProvider<Hackathon?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getActiveHackathon();
});

final adminDashboardProvider =
    FutureProvider.family<AdminDashboard, String>((ref, hackathonId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getAdminDashboard(hackathonId);
});

final teamsProvider =
    FutureProvider.family<TeamListResponse, String>((ref, hackathonId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getTeams(hackathonId);
});

final criteriaProvider = FutureProvider.family<CriteriaListResponse, String>(
    (ref, hackathonId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getCriteria(hackathonId);
});

final assignmentsProvider =
    FutureProvider.family<List<Assignment>, String>((ref, hackathonId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getAssignments(hackathonId);
});

final myAssignedTeamsProvider =
    FutureProvider.family<AssignedTeamListResponse, String>(
        (ref, hackathonId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getMyAssignedTeams(hackathonId);
});

final leaderboardProvider = FutureProvider.family<LeaderboardResponse, String>(
    (ref, hackathonId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getLeaderboard(hackathonId);
});

final timerProvider =
    FutureProvider.family<TimerResponse, String>((ref, hackathonId) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getTimer(hackathonId);
});
