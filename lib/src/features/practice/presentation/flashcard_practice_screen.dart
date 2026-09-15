import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vocabulary/domain/entry.dart';
import 'practice_providers.dart';
import 'practice_summary_screen.dart';
import 'widgets/practice_notebook_card.dart';

class FlashcardPracticeScreen extends ConsumerStatefulWidget {
  final List<Entry> initialLibrary;
  final VoidCallback onExit;

  const FlashcardPracticeScreen({
    super.key,
    required this.initialLibrary,
    required this.onExit,
  });

  @override
  ConsumerState<FlashcardPracticeScreen> createState() =>
      _FlashcardPracticeScreenState();
}

class _FlashcardPracticeScreenState
    extends ConsumerState<FlashcardPracticeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      final year = now.year.toString().padLeft(4, '0');
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final todayStr = '$year-$month-$day';

      ref.read(practiceSessionProvider.notifier).startSession(
            library: widget.initialLibrary,
            todayDueDate: todayStr,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(practiceSessionProvider);
    final controller = ref.read(practiceSessionProvider.notifier);
    final ttsService = ref.read(ttsServiceProvider);

    if (state.isCompleted) {
      return PracticeSummaryScreen(
        state: state,
        onDone: widget.onExit,
      );
    }

    if (state.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: TextButton(
            onPressed: widget.onExit,
            child: const Text('Done'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No entries available for practice.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: widget.onExit,
                child: const Text('Add word'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return const SizedBox.shrink();

    final totalQuestions = state.questions.length;
    final currentNumber = state.currentIndex + 1;
    final progressRatio = currentNumber / totalQuestions;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: widget.onExit,
          child: const Text('Done'),
        ),
        title: Text(
          currentQuestion.isRepeat
              ? 'Repeat $currentNumber of $totalQuestions'
              : 'Question $currentNumber of $totalQuestions',
          style: theme.textTheme.bodyMedium,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Listen',
            onPressed: () {
              ttsService.speak(currentQuestion.entry.english);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progressRatio,
            minHeight: 2,
            backgroundColor: theme.colorScheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          if (state.saveError != null)
            Container(
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      state.saveError!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.retrySave(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: PracticeNotebookCard(
              question: currentQuestion,
              isRevealed: state.isRevealed,
              onTapReveal: () => controller.reveal(),
            ),
          ),
          // Override banner if single-tap correction is available
          if (state.canOverride)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: TextButton.icon(
                onPressed: () => controller.countAsCorrect(),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Count as correct'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
          // Bottom Thumb Action Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: state.isRevealed
                  ? Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: state.isSaving
                                  ? null
                                  : () => controller.gradeCurrent(correct: false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: theme.colorScheme.outline),
                                foregroundColor: theme.colorScheme.onSurface,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: const Text(
                                "Didn't know",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: state.isSaving
                                  ? null
                                  : () => controller.gradeCurrent(correct: true),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: const Text(
                                'Knew it',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => controller.reveal(),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text(
                          'Show answer',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
