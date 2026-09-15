import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vocabulary/domain/entry.dart';
import '../domain/practice_question.dart';
import 'practice_providers.dart';
import 'practice_session_controller.dart';
import 'practice_session_state.dart';
import 'practice_summary_screen.dart';
import 'widgets/multiple_choice_practice_widget.dart';
import 'widgets/practice_notebook_card.dart';
import 'widgets/typing_practice_widget.dart';

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
  final TextEditingController _typingInputController = TextEditingController();

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
  void dispose() {
    _typingInputController.dispose();
    super.dispose();
  }

  Future<void> _handleAudioTap() async {
    final state = ref.read(practiceSessionProvider);
    final question = state.currentQuestion;
    if (question == null) return;

    final ttsService = ref.read(ttsServiceProvider);
    final success = await ttsService.speak(question.entry.english);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'English pronunciation unavailable. Install an English (US) voice in your device\'s speech settings.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(practiceSessionProvider);
    final controller = ref.read(practiceSessionProvider.notifier);

    if (state.isCompleted) {
      return PracticeSummaryScreen(
        state: state,
        onDone: widget.onExit,
      );
    }

    if (state.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: 80,
          leading: TextButton(
            onPressed: widget.onExit,
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
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
        leadingWidth: 80,
        leading: TextButton(
          onPressed: widget.onExit,
          child: const Text(
            'Done',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
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
            onPressed: _handleAudioTap,
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

          // Question Format Specific Body
          Expanded(
            child: _buildFormatBody(currentQuestion, state, controller),
          ),

          // Single-tap "Count as correct" override banner
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

          // Bottom Action Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: _buildBottomActionBar(currentQuestion, state, controller, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatBody(
    PracticeQuestion question,
    PracticeSessionState state,
    PracticeSessionNotifier controller,
  ) {
    switch (question.format) {
      case QuestionFormat.flashcard:
        return PracticeNotebookCard(
          question: question,
          isRevealed: state.isRevealed,
          onTapReveal: () => controller.reveal(),
        );
      case QuestionFormat.multipleChoice:
        return MultipleChoicePracticeWidget(
          question: question,
          state: state,
          onSelectOption: (index) {
            controller.selectOption(index);
          },
        );
      case QuestionFormat.typing:
        return TypingPracticeWidget(
          question: question,
          state: state,
          onSubmit: (text) {
            controller.submitTypedAnswer(text);
          },
        );
    }
  }

  Widget _buildBottomActionBar(
    PracticeQuestion question,
    PracticeSessionState state,
    PracticeSessionNotifier controller,
    ThemeData theme,
  ) {
    switch (question.format) {
      case QuestionFormat.flashcard:
        if (state.isRevealed) {
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          return LayoutBuilder(
            builder: (context, constraints) {
              final shouldStack = textScale > 1.25 || constraints.maxWidth < 320;
              if (shouldStack) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
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
                  ],
                );
              }

              return Row(
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
              );
            },
          );
        } else {
          return SizedBox(
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
          );
        }

      case QuestionFormat.multipleChoice:
        if (state.isRevealed) {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: state.isSaving
                  ? null
                  : () => controller.gradeCurrent(
                        correct: state.lastAttemptedGrade ?? false,
                      ),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        } else {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: null, // Disabled until an option is selected
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text(
                'Select an option above',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

      case QuestionFormat.typing:
        if (state.isRevealed) {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: state.isSaving
                  ? null
                  : () => controller.gradeCurrent(
                        correct: state.lastAttemptedGrade ?? false,
                      ),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        } else {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                final typedText = state.typedText ?? '';
                controller.submitTypedAnswer(typedText);
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
              child: const Text(
                'Check answer',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }
    }
  }
}
