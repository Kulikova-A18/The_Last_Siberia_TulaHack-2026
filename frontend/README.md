frontend/
├── lib/
│ ├── main.dart # Точка входа, навигация по ролям
│ ├── app.dart # MaterialApp + тема + GoRouter
│ ├── models/ # Модели данных
│ │ ├── user.dart
│ │ ├── team.dart
│ │ ├── criterion.dart
│ │ ├── evaluation.dart
│ │ └── hackathon.dart
│ ├── services/ # Сервисы API (закомментированы)
│ │ ├── api_service.dart # Dio-клиент + заглушки
│ │ ├── auth_service.dart
│ │ └── storage_service.dart # Токены, пользователь
│ ├── providers/ # Riverpod-провайдеры
│ │ ├── auth_provider.dart
│ │ ├── hackathon_provider.dart
│ │ ├── teams_provider.dart
│ │ ├── criteria_provider.dart
│ │ ├── evaluations_provider.dart
│ │ └── results_provider.dart
│ ├── screens/
│ │ ├── login_screen.dart
│ │ ├── admin/
│ │ │ ├── admin_dashboard_screen.dart
│ │ │ ├── users_screen.dart
│ │ │ ├── teams_screen.dart
│ │ │ ├── criteria_screen.dart
│ │ │ ├── assignments_screen.dart
│ │ │ └── results_screen.dart
│ │ ├── expert/
│ │ │ ├── expert_dashboard_screen.dart
│ │ │ ├── assigned_teams_screen.dart
│ │ │ └── evaluation_form_screen.dart
│ │ ├── team/
│ │ │ ├── team_profile_screen.dart
│ │ │ └── team_result_screen.dart
│ │ └── public/
│ │ └── public_leaderboard_screen.dart
│ └── widgets/
│ ├── app_drawer.dart
│ ├── timer_widget.dart
│ ├── kpi_card.dart
│ ├── status_badge.dart
│ ├── score_input.dart
│ └── leaderboard_table.dart
├── pubspec.yaml
└── README.md
