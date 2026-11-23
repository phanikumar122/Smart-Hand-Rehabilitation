import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/rehab_session.dart';
import '../services/storage_service.dart';
import '../widgets/app_components.dart';

class SessionHistoryView extends StatefulWidget {
  const SessionHistoryView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SessionHistoryView> createState() => _SessionHistoryViewState();
}

class _SessionHistoryViewState extends State<SessionHistoryView> {
  final StorageService _storageService = StorageService();
  List<RehabSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _storageService.getSessions();
    sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  Future<void> _confirmClear() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined),
        title: const Text('Clear History'),
        content: const Text(
          'Delete every saved rehabilitation session? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear != true) return;
    await _storageService.clearSessions();
    await _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _sessions.isEmpty
        ? const EmptyState(
            icon: Icons.auto_graph_rounded,
            title: 'No sessions saved yet.',
            message: 'Complete a guided session to begin building your recovery timeline.',
          )
        : RefreshIndicator(
            onRefresh: _loadSessions,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 32),
              itemCount: _sessions.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return SectionHeader(
                    title: 'Session History',
                    caption:
                        '${_sessions.length} completed ${_sessions.length == 1 ? 'session' : 'sessions'}',
                    action: IconButton(
                      tooltip: 'Clear History',
                      onPressed: _confirmClear,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  );
                }
                final session = _sessions[index - 1];
                return _SessionCard(session: session, index: index - 1);
              },
            ),
          );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Session History')),
      body: ResponsivePage(child: body),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.index});
  final RehabSession session;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StaggeredReveal(
      index: index.clamp(0, 4),
      child: ClinicalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.check_rounded, color: colors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM d, y').format(session.startTime),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        DateFormat('h:mm a').format(session.startTime),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  label:
                      '${session.duration.inMinutes}m ${session.duration.inSeconds % 60}s',
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _CompactStat(
                    label: 'Max grip',
                    value: '${session.maxGrip}',
                    tone: colors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactStat(
                    label: 'Avg movement',
                    value: '${session.averageMovement}°',
                    tone: colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CompactStat(
                    label: 'Readings',
                    value: '${session.readingCount}',
                    tone: colors.tertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.label,
    required this.value,
    required this.tone,
  });
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: tone),
      ),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}
