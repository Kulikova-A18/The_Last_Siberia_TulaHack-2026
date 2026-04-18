import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hackathon.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final hackathonProvider = FutureProvider<Hackathon?>((ref) async {
  final hackathonId = ref.watch(hackathonIdProvider);
  // final api = ApiService();
  // return await api.getActiveHackathon();

  // Демо-данные
  return Hackathon(
    id: hackathonId,
    title: 'HackRank 2026',
    description: 'Демо-хакатон',
    startAt: DateTime.now().subtract(const Duration(days: 1)),
    endAt: DateTime.now().add(const Duration(days: 2)),
    status: 'active',
  );
});

final adminDashboardProvider =
    FutureProvider.family<AdminDashboard, String>((ref, hackathonId) async {
  // final api = ApiService();
  // return await api.getAdminDashboard(hackathonId);

  // Демо-данные
  return AdminDashboard(
    teamsTotal: 12,
    expertsTotal: 5,
    criteriaTotal: 4,
    evaluationsSubmitted: 28,
    evaluationsDraft: 8,
    evaluationsTotalExpected: 48,
    leaderboardTop: [
      LeaderboardEntry(
          place: 1, teamId: '1', teamName: 'CodeMasters', finalScore: 92.5),
      LeaderboardEntry(
          place: 2, teamId: '2', teamName: 'ByteForce', finalScore: 87.3),
      LeaderboardEntry(
          place: 3, teamId: '3', teamName: 'InnovateX', finalScore: 84.1),
    ],
    expertsProgress: [
      ExpertProgress(
          expertId: 'e1',
          expertName: 'Иван Петров',
          submitted: 6,
          totalAssigned: 8),
      ExpertProgress(
          expertId: 'e2',
          expertName: 'Елена Смирнова',
          submitted: 8,
          totalAssigned: 10),
    ],
    nextDeadline: Deadline(
      id: 'd1',
      title: 'Окончание оценивания',
      deadlineAt: DateTime.now().add(const Duration(hours: 5)),
    ),
  );
});
