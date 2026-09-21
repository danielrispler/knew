import 'package:flutter/material.dart';
import 'package:knew/src/core/l10n/l10n.dart';
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

  String _stageName(Stage stage, AppLocalizations l10n) {
    switch (stage) {
      case Stage.newStage:
        return l10n.stageNew;
      case Stage.familiar:
        return l10n.stageFamiliar;
      case Stage.learned:
        return l10n.stageLearned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accuracyPercent = (state.accuracy * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.practiceSummary),
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
                        l10n.sessionCompleteDesc(state.reviewedCount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (state.isExtraPractice) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.extraPractice,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ] else if (state.isEarlyReview) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.earlyReviewBadge,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (!state.isExtraPractice &&
                  state.stageMovements.isNotEmpty) ...[
                Text(
                  l10n.stageProgress,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: state.stageMovements.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final movement = state.stageMovements[index];
                      return ListTile(
                        title: Text(movement.entry.english),
                        subtitle: Text(
                          '${_stageName(movement.fromStage, l10n)} → ${_stageName(movement.toStage, l10n)}',
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
                  child: Text(l10n.done, style: const TextStyle(fontSize: 16)),
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
