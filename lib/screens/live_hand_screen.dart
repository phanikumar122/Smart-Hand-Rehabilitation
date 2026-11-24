import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';

import 'package:provider/provider.dart';

import '../providers/glove_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_hand.dart';
import '../widgets/app_components.dart';

class LiveHandScreen extends StatefulWidget {
  const LiveHandScreen({super.key});
  @override
  State<LiveHandScreen> createState() => _LiveHandScreenState();
}

class _LiveHandScreenState extends State<LiveHandScreen> {
  int? _selectedFinger;
  @override
  Widget build(BuildContext context) {
    final data = context.watch<GloveDataProvider>().currentData;
    final colors = Theme.of(context).colorScheme;
    final values = [
      data?.thumb,
      data?.index,
      data?.middle,
      data?.ring,
      data?.pinky,
    ];
    final bend = data == null
        ? null
        : _selectedFinger == null
        ? values.fold<int>(0, (sum, value) => sum + value!) ~/ 5
        : values[_selectedFinger!];
    final label = _selectedFinger == null
        ? context.strings.averageBend
        : context.strings.fingerBend(
            context.strings.fingerName(_selectedFinger!),
          );
    final diagram = ClinicalCard(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.strings.movement,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1.12,
            child: AnimatedHand(
              data: data,
              selectedFinger: _selectedFinger,
              onFingerSelected: (finger) =>
                  setState(() => _selectedFinger = finger),
            ),
          ),
          Text(
            context.strings.tapFinger,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var finger = -1; finger < 5; finger++)
              ChoiceChip(
                label: Text(
                  finger < 0
                      ? context.strings.all
                      : context.strings.fingerName(finger),
                ),
                selected: _selectedFinger == (finger < 0 ? null : finger),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                selectedColor: colors.primary,
                labelStyle: TextStyle(
                  color: _selectedFinger == (finger < 0 ? null : finger)
                      ? colors.onPrimary
                      : colors.onSurface,
                ),
                onSelected: (_) => setState(
                  () => _selectedFinger = finger < 0 ? null : finger,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ClinicalCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          bend == null ? '--' : '$bend°',
                          key: const ValueKey('selected-bend'),
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Tooltip(
                      message: context.strings.gripHint,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            context.strings.grip,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data?.grip.toString() ?? '--',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (bend ?? 0) / 90),
                duration: data == null
                    ? Duration.zero
                    : AppMotion.duration(context, AppMotion.fast),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    return Scaffold(
      body: ResponsivePage(
        maxWidth: 960,
        child: ListView(
          children: [
            AppPageHeader(
              title: context.strings.liveHand,
              trailing: StatusPill(
                label: data == null
                    ? context.strings.noSignal
                    : context.strings.live,
                icon: data == null
                    ? Icons.sensors_off_rounded
                    : Icons.sensors_rounded,
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 680) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: diagram),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: detail),
                    ],
                  );
                }
                return Column(
                  children: [diagram, const SizedBox(height: 16), detail],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
