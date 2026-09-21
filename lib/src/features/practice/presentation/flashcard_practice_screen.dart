import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knew/src/core/l10n/l10n.dart';
import '../../vocabulary/domain/entry.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/practice_question.dart';
import '../domain/due_queue_selector.dart';
import 'practice_providers.dart';
import 'practice_session_controller.dart';
import 'practice_session_state.dart';
import 'practice_summary_screen.dart';
import 'widgets/multiple_choice_practice_widget.dart';
import 'widgets/practice_notebook_card.dart';
import 'widgets/typing_practice_widget.dart';
import 'widgets/cloze_practice_widget.dart';
import 'widgets/sentence_production_practice_widget.dart';

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
  bool _checkedDue = false;
  String _todayStr = '';
  int _sessionSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = await ref.read(settingsProvider.future);
      if (!mounted) return;

      final now = DateTime.now();
      final year = now.year.toString().padLeft(4, '0');
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final todayStr = '$year-$month-$day';

      _todayStr = todayStr;
      _sessionSize = settings.sessionSize;

      final hasDue = DueQueueSelector.hasDueEntries(
        library: widget.initialLibrary,
        todayDueDate: todayStr,
      );

      if (hasDue || widget.initialLibrary.isEmpty) {
        ref
            .read(practiceSessionProvider.notifier)
            .startSession(
              library: widget.initialLibrary,
              todayDueDate: todayStr,
              requestedSessionSize: settings.sessionSize,
            );
      } else {
        setState(() {
          _checkedDue = true;
        });
      }
    });
  }

  void _startPracticeSession({bool isEarlyReview = false}) {
    ref
        .read(practiceSessionProvider.notifier)
        .startSession(
          library: widget.initialLibrary,
          todayDueDate: _todayStr,
          requestedSessionSize: _sessionSize,
          isEarlyReview: isEarlyReview,
        );
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
        SnackBar(
          content: Text(context.l10n.pronunciationUnavailable),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildAllCaughtUpScreen(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final reviewedToday = DueQueueSelector.getReviewedToday(
      library: widget.initialLibrary,
      todayDueDate: _todayStr,
    );

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        leading: TextButton(
          onPressed: widget.onExit,
          child: Text(
            context.l10n.done,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.allCaughtUpTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.allCaughtUpDesc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (reviewedToday.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        l10n.reviewedTodayCount(reviewedToday.length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: () => _startPracticeSession(isEarlyReview: true),
                  icon: const Icon(Icons.trending_up),
                  label: Text(l10n.earlyReviewTitle),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.earlyReviewDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => _startPracticeSession(isEarlyReview: false),
                  icon: const Icon(Icons.replay),
                  label: Text(l10n.repracticeTitle),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.repracticeDesc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(practiceSessionProvider);
    final controller = ref.read(practiceSessionProvider.notifier);

    if (!_checkedDue && !state.sessionStarted) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: 80,
          leading: TextButton(
            onPressed: widget.onExit,
            child: Text(
              context.l10n.done,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!state.sessionStarted) {
      return _buildAllCaughtUpScreen(context);
    }

    if (state.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leadingWidth: 80,
          leading: TextButton(
            onPressed: widget.onExit,
            child: Text(
              context.l10n.done,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.noEntriesForPractice,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: widget.onExit,
                child: Text(context.l10n.addEntry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isCompleted) {
      return PracticeSummaryScreen(state: state, onDone: widget.onExit);
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
          child: Text(
            context.l10n.done,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentQuestion.isRepeat
                  ? context.l10n.repeatProgress(currentNumber, totalQuestions)
                  : context.l10n.questionProgress(
                      currentNumber,
                      totalQuestions,
                    ),
              style: theme.textTheme.bodyMedium,
            ),
            if (state.isExtraPractice)
              Text(
                context.l10n.extraPractice,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.tertiary,
                ),
              )
            else if (state.isEarlyReview)
              Text(
                context.l10n.earlyReviewBadge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: context.l10n.listen,
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
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
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
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.retrySave(),
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            ),

          // Question Format Specific Body
          Expanded(child: _buildFormatBody(currentQuestion, state, controller)),

          // Single-tap "Count as correct" override banner
          if (state.canOverride)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: TextButton.icon(
                onPressed: () => controller.countAsCorrect(),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(context.l10n.countAsCorrect),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),

          // Bottom Action Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: _buildBottomActionBar(
                currentQuestion,
                state,
                controller,
                theme,
              ),
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
          textController: _typingInputController,
          onSubmit: (text) {
            controller.submitTypedAnswer(text);
          },
        );
      case QuestionFormat.cloze:
        return ClozePracticeWidget(
          question: question,
          state: state,
          onSubmit: controller.submitClozeAnswer,
          onHint: controller.showClozeHint,
          onConfirmTypo: controller.confirmClozeTypo,
          onShowAnswer: controller.showClozeAnswer,
        );
      case QuestionFormat.sentenceProduction:
        return SentenceProductionPracticeWidget(
          question: question,
          state: state,
          controller: _typingInputController,
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
              final shouldStack =
                  textScale > 1.25 || constraints.maxWidth < 320;
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
                        child: Text(
                          context.l10n.didntKnow,
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
                        child: Text(
                          context.l10n.knewIt,
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
                        child: Text(
                          context.l10n.didntKnow,
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
                        child: Text(
                          context.l10n.knewIt,
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
              child: Text(
                context.l10n.showAnswer,
                style: const TextStyle(fontSize: 16),
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
              child: Text(
                context.l10n.next,
                style: const TextStyle(fontSize: 16),
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
              child: Text(
                context.l10n.selectOptionAbove,
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
              child: Text(
                context.l10n.next,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        } else {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                controller.submitTypedAnswer(_typingInputController.text);
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(
                context.l10n.checkAnswer,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }
      case QuestionFormat.cloze:
        if (!state.isRevealed) return const SizedBox.shrink();
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: state.isSaving
                ? null
                : () => controller.gradeCurrent(
                    correct: state.lastAttemptedGrade ?? false,
                  ),
            child: Text(context.l10n.next),
          ),
        );
      case QuestionFormat.sentenceProduction:
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
              child: Text(context.l10n.next),
            ),
          );
        }
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: state.isEvaluatingSentence
                ? null
                : () => controller.submitSentence(
                    _typingInputController.text,
                    feedbackLanguage:
                        Localizations.localeOf(context).languageCode == 'he'
                        ? 'Hebrew'
                        : 'English',
                  ),
            child: Text(context.l10n.getFeedback),
          ),
        );
    }
  }
}
