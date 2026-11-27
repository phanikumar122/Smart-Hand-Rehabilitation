import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';

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
  bool _loadFailed = false;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    StorageService.historyRevision.addListener(_reload);
    _loadSessions();
  }

  void _reload() => _loadSessions();

  @override
  void dispose() {
    StorageService.historyRevision.removeListener(_reload);
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final request = ++_loadRequest;
    try {
      final sessions = await _storageService.getSessions();
      sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _sessions = sessions;
        _isLoading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _confirmClear() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined),
        title: Text(context.strings.clearHistory),
        content: Text(context.strings.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.strings.clear),
          ),
        ],
      ),
    );
    if (clear != true || !mounted) return;
    try {
      await _storageService.clearSessions();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.strings.historyClearFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _loadFailed
        ? EmptyState(
            icon: Icons.error_outline_rounded,
            title: context.strings.sessionHistory,
            message: context.strings.historyLoadFailed,
            action: TextButton(
              onPressed: _loadSessions,
              child: Text(context.strings.retryHistory),
            ),
          )
        : _sessions.isEmpty
        ? EmptyState(
            icon: Icons.auto_graph_rounded,
            title: context.strings.noSessions,
            message: context.strings.completeSessionHint,
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
                    title: context.strings.sessionHistory,
                    caption: context.strings.completedSessions(
                      _sessions.length,
                    ),
                    action: IconButton(
                      tooltip: context.strings.clearHistory,
                      onPressed: _confirmClear,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  );
                }
                final session = _sessions[index - 1];
                return _SessionCard(session: session);
              },
            ),
          );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(context.strings.sessionHistory)),
      body: ResponsivePage(child: body),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final RehabSession session;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final heading = Row(
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
                DateFormat.yMMMd(context.strings.localeName)
                    .format(session.startTime),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                DateFormat.Hm(context.strings.localeName)
                    .format(session.startTime),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
    final duration = StatusPill(
      label: context.strings.sessionDuration(
        session.duration.inMinutes,
        session.duration.inSeconds % 60,
      ),
      icon: Icons.timer_outlined,
    );
    return AppFadeIn(
      child: ClinicalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final stack =
                    MediaQuery.textScalerOf(context).scale(16) > 24 ||
                    (context.strings.localeName != 'en' &&
                        constraints.maxWidth < 340);
                if (stack) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [heading, const SizedBox(height: 12), duration],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: heading),
                    duration,
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final stats = [
                  _CompactStat(
                    label: context.strings.maxGrip,
                    value: '${session.maxGrip}',
                    tone: colors.secondary,
                  ),
                  _CompactStat(
                    label: context.strings.averageMovement,
                    value: '${session.averageMovement}/90',
                    tone: colors.primary,
                  ),
                  _CompactStat(
                    label: context.strings.readings,
                    value: '${session.readingCount}',
                    tone: colors.tertiary,
                  ),
                ];
                if (MediaQuery.textScalerOf(context).scale(16) > 24) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final stat in stats)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: stat,
                        ),
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var index = 0; index < stats.length; index++) ...[
                      if (index > 0) const SizedBox(width: 10),
                      Expanded(child: stats[index]),
                    ],
                  ],
                );
              },
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
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}
