import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../services/api/api_client.dart';

class ApiLogger {
  static final List<String> _logs = [];
  static final List<Function(String)> _listeners = [];

  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final formattedMessage = '[$timestamp] $message';
    _logs.add(formattedMessage);
    if (_logs.length > 100) _logs.removeAt(0);
    for (final listener in _listeners) {
      listener(formattedMessage);
    }
    debugPrint(message);
  }

  static void addListener(Function(String) listener) =>
      _listeners.add(listener);
  static void removeListener(Function(String) listener) =>
      _listeners.remove(listener);
  static List<String> getLogs() => List.unmodifiable(_logs);

  static void clear() {
    _logs.clear();
    for (final listener in _listeners) {
      listener('[LOGS CLEARED]');
    }
  }
}

class DebugDrawer extends StatefulWidget {
  final GoRouter router;
  final VoidCallback onLogout;
  final User? currentUser;

  const DebugDrawer(
      {super.key,
      required this.router,
      required this.onLogout,
      this.currentUser});

  @override
  State<DebugDrawer> createState() => _DebugDrawerState();
}

class _DebugDrawerState extends State<DebugDrawer> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _apiLogs = [];

  @override
  void initState() {
    super.initState();
    ApiLogger.addListener(_onLogAdded);
    ApiClient.setLogCallback(ApiLogger.log);
    ApiLogger.log('🟢 Debug Drawer initialized');
    ApiLogger.log('📡 API Base URL: http://192.168.5.46:8000/api/v1');
    if (widget.currentUser != null) {
      ApiLogger.log(
          '👤 User: ${widget.currentUser!.fullName} (${widget.currentUser!.roleString})');
    }
  }

  @override
  void dispose() {
    ApiLogger.removeListener(_onLogAdded);
    super.dispose();
  }

  void _onLogAdded(String message) {
    setState(() {
      _apiLogs.add(message);
      if (_apiLogs.length > 100) _apiLogs.removeAt(0);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _clearLogs() {
    setState(() => _apiLogs.clear());
    ApiLogger.clear();
  }

  void _navigate(String route) {
    Navigator.of(context).pop();
    widget.router.push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 400,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer),
            child: Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 12),
                const Text('Отладка API',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.currentUser != null
                        ? '👤 ${widget.currentUser!.fullName}'
                        : '👤 Не авторизован',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (widget.currentUser != null) ...[
                  const SizedBox(height: 4),
                  Text('🆔 ${widget.currentUser!.id}'),
                  const SizedBox(height: 4),
                  Text('🔑 Роль: ${widget.currentUser!.roleString}'),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _NavChip(label: '🏠 Public', onTap: () => _navigate('/public')),
                _NavChip(label: '🔐 Login', onTap: () => _navigate('/login')),
                _NavChip(label: '👑 Admin', onTap: () => _navigate('/admin')),
                _NavChip(
                    label: '👨‍⚖️ Expert', onTap: () => _navigate('/expert')),
                _NavChip(label: '👥 Team', onTap: () => _navigate('/team')),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ApiLogger.log('📤 GET /hackathons/active');
                    ApiLogger.log('⏳ Waiting for response...');
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Тест API'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                    onPressed: _clearLogs,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Очистить')),
                const Spacer(),
                if (widget.currentUser != null)
                  OutlinedButton.icon(
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('Выйти'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red)),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text('API Логи (${_apiLogs.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 4),
                const Text('Live', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _apiLogs.isEmpty ? 1 : _apiLogs.length,
                itemBuilder: (context, index) {
                  if (_apiLogs.isEmpty) {
                    return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'Логи пусты. Нажмите "Тест API" или выполните запрос в приложении.',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12)));
                  }
                  final log = _apiLogs[index];
                  Color color = Colors.white;
                  if (log.contains('📤')) color = Colors.cyan;
                  if (log.contains('📥')) color = Colors.lightGreen;
                  if (log.contains('❌')) color = Colors.red;
                  if (log.contains('✅')) color = Colors.green;
                  if (log.contains('⏳')) color = Colors.yellow;
                  if (log.contains('🔄')) color = Colors.orange;
                  return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(log,
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontFamily: 'monospace')));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}
