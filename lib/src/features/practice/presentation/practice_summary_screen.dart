import 'package:flutter/material.dart';
import '../../vocabulary/domain/entry.dart';
import 'practice_session_state.dart';

class PracticeSummaryScreen extends StatelessWidget {
  final PracticeSessionState state;
  final VoidCallback onDone;

  const PracticeSummaryScreen({
    super.key,
    required this.state,
    required this.onDone,
  });

  String _stageName(Stage stage) {
    switch (stage) {
      case Stage.newStage:
        return 'New';
      case Stage.familiar:
        return 'Familiar';
      case Stage.learned:
        return 'Learned';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracyPercent = (state.accuracy * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isExtraPractice ? 'Extra Practice Summary' : 'Practice Summary'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        '$accuracyPercent%',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Accuracy (${state.reviewedCount} items reviewed)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!state.isExtraPractice && state.stageMovements.isNotEmpty) ...[
                Text(
                  'Stage Progress',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: state.stageMovements.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final movement = state.stageMovements[index];
                      return ListTile(
                        title: Text(movement.entry.english),
                        subtitle: Text(
                          '${_stageName(movement.fromStage)} → ${_stageName(movement.toStage)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else
                const Spacer(),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Done', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
