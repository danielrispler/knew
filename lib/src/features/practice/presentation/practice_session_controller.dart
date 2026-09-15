import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vocabulary/domain/entry.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import '../domain/answer_checker.dart';
import '../domain/distractor_generator.dart';
import '../domain/due_queue_selector.dart';
import '../domain/practice_question.dart';
import '../domain/practice_scheduler.dart';
import '../domain/question_format_selector.dart';
import 'practice_session_state.dart';

class PracticeSessionNotifier extends Notifier<PracticeSessionState> {
  @override
  PracticeSessionState build() {
    return const PracticeSessionState();
  }

  void startSession({
    required List<Entry> library,
    required String todayDueDate,
    int requestedSessionSize = 20,
    Random? random,
  }) {
    final selection = DueQueueSelector.selectQueue(
      library: library,
      todayDueDate: todayDueDate,
      requestedSessionSize: requestedSessionSize,
    );

    final rng = random ?? Random();
    final preSnapshots = <String, Entry>{};
    final questions = <PracticeQuestion>[];

    QuestionFormat? lastFormat;
    int consecutiveFormatCount = 0;

    for (final entry in selection.entries) {
      preSnapshots[entry.id] = entry;

      final dir = rng.nextBool()
          ? PromptDirection.englishToHebrew
          : PromptDirection.hebrewToEnglish;

      final format = QuestionFormatSelector.selectFormat(
        entry: entry,
        direction: dir,
        library: library,
        wasAboveLevelZeroAtSessionStart: entry.level > 0,
        lastFormat: lastFormat,
        consecutiveCount: consecutiveFormatCount,
        random: rng,
      );

      if (format == lastFormat) {
        consecutiveFormatCount++;
      } else {
        lastFormat = format;
        consecutiveFormatCount = 1;
      }

      DistractorResult? distractorResult;
      if (format == QuestionFormat.multipleChoice) {
        distractorResult = DistractorGenerator.generate(
          target: entry,
          direction: dir,
          library: library,
          random: rng,
        );
      }

      questions.add(PracticeQuestion(
        entry: entry,
        direction: dir,
        format: format,
        isRepeat: false,
        distractorResult: distractorResult,
      ));
    }

    state = PracticeSessionState(
      initialQueue: selection.entries,
      questions: questions,
      currentIndex: 0,
      isRevealed: false,
      isExtraPractice: selection.isExtraPractice,
      firstPassPreSnapshots: preSnapshots,
      firstPassPostSnapshots: {},
      repeatQueue: [],
      isCompleted: questions.isEmpty,
      canOverride: false,
      selectedOptionIndex: null,
      answerCheckResult: null,
      typedText: null,
    );
  }

  void reveal() {
    if (state.isRevealed || state.isCompleted) return;
    state = state.copyWith(isRevealed: true);
  }

  void selectOption(int optionIndex) {
    final question = state.currentQuestion;
    if (question == null || state.isRevealed || state.isCompleted) return;
    if (question.format != QuestionFormat.multipleChoice || question.distractorResult == null) return;

    final distractorResult = question.distractorResult!;
    final isCorrect = (optionIndex == distractorResult.correctOptionIndex);

    state = state.copyWith(
      selectedOptionIndex: optionIndex,
      isRevealed: true,
      lastAttemptedGrade: isCorrect,
    );
  }

  AnswerCheckResult submitTypedAnswer(String text) {
    final question = state.currentQuestion;
    if (question == null || state.isCompleted) {
      return const AnswerCheckResult(AnswerCheckStatus.noMatch);
    }

    final result = question.direction == PromptDirection.englishToHebrew
        ? AnswerChecker.checkHebrewAnswer(userInput: text, entry: question.entry)
        : AnswerChecker.checkEnglishAnswer(userInput: text, entry: question.entry);

    final isCorrect = (result.status == AnswerCheckStatus.exactMatch ||
        result.status == AnswerCheckStatus.typoMatch);

    state = state.copyWith(
      typedText: text,
      answerCheckResult: result,
      isRevealed: true,
      lastAttemptedGrade: isCorrect,
    );

    return result;
  }

  Future<void> gradeCurrent({required bool correct, DateTime? now}) async {
    final question = state.currentQuestion;
    if (question == null || state.isSaving || state.isCompleted) return;

    state = state.copyWith(
      isSaving: true,
      saveError: null,
      lastAttemptedGrade: correct,
    );

    final entry = question.entry;
    final isFirstPass = !question.isRepeat;

    if (isFirstPass && !state.isExtraPractice) {
      final updatedEntry = correct
          ? PracticeScheduler.gradeCorrect(entry, now: now)
          : PracticeScheduler.gradeIncorrect(entry, now: now);

      try {
        final repository = ref.read(wordsRepositoryProvider);
        await repository.updateEntry(updatedEntry);

        final newPostSnapshots = Map<String, Entry>.from(state.firstPassPostSnapshots);
        newPostSnapshots[entry.id] = updatedEntry;

        final newRepeatQueue = List<Entry>.from(state.repeatQueue);
        if (!correct) {
          newRepeatQueue.add(entry);
        }

        _advanceToNextQuestion(
          postSnapshots: newPostSnapshots,
          repeatQueue: newRepeatQueue,
          canOverride: !correct,
          lastGradedId: entry.id,
        );
      } catch (e) {
        state = state.copyWith(
          isSaving: false,
          saveError: 'Progress was not saved: ${e.toString()}',
        );
        return;
      }
    } else {
      final newRepeatQueue = List<Entry>.from(state.repeatQueue);
      if (!correct && isFirstPass) {
        newRepeatQueue.add(entry);
      }

      _advanceToNextQuestion(
        postSnapshots: state.firstPassPostSnapshots,
        repeatQueue: newRepeatQueue,
        canOverride: false,
        lastGradedId: null,
      );
    }
  }

  Future<void> retrySave({DateTime? now}) async {
    final lastGrade = state.lastAttemptedGrade;
    if (lastGrade == null) return;
    await gradeCurrent(correct: lastGrade, now: now);
  }

  Future<void> countAsCorrect({DateTime? now}) async {
    final lastId = state.lastGradedEntryId;
    if (lastId == null || !state.canOverride || state.isExtraPractice) return;

    final preEntry = state.firstPassPreSnapshots[lastId];
    if (preEntry == null) return;

    state = state.copyWith(isSaving: true, saveError: null);

    final overriddenEntry = PracticeScheduler.overrideWrongWithCorrect(preEntry, now: now);

    try {
      final repository = ref.read(wordsRepositoryProvider);
      await repository.updateEntry(overriddenEntry);

      final newPostSnapshots = Map<String, Entry>.from(state.firstPassPostSnapshots);
      newPostSnapshots[lastId] = overriddenEntry;

      final newRepeatQueue = state.repeatQueue.where((e) => e.id != lastId).toList();
      final newQuestions = state.questions.where((q) => !(q.isRepeat && q.entry.id == lastId)).toList();

      state = state.copyWith(
        isSaving: false,
        saveError: null,
        firstPassPostSnapshots: newPostSnapshots,
        repeatQueue: newRepeatQueue,
        questions: newQuestions,
        canOverride: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        saveError: 'Override failed to save: ${e.toString()}',
      );
    }
  }

  void _advanceToNextQuestion({
    required Map<String, Entry> postSnapshots,
    required List<Entry> repeatQueue,
    required bool canOverride,
    required String? lastGradedId,
  }) {
    final nextIndex = state.currentIndex + 1;
    final questions = List<PracticeQuestion>.from(state.questions);

    if (nextIndex >= questions.length && repeatQueue.isNotEmpty) {
      final rng = Random();
      QuestionFormat? lastFormat = questions.isNotEmpty ? questions.last.format : null;
      int consecutiveCount = 1;

      for (final repeatEntry in repeatQueue) {
        if (!questions.any((q) => q.isRepeat && q.entry.id == repeatEntry.id)) {
          final dir = rng.nextBool()
              ? PromptDirection.englishToHebrew
              : PromptDirection.hebrewToEnglish;

          final preEntry = state.firstPassPreSnapshots[repeatEntry.id];
          final wasAboveZero = (preEntry?.level ?? repeatEntry.level) > 0;

          final format = QuestionFormatSelector.selectFormat(
            entry: repeatEntry,
            direction: dir,
            library: state.initialQueue,
            wasAboveLevelZeroAtSessionStart: wasAboveZero,
            lastFormat: lastFormat,
            consecutiveCount: consecutiveCount,
            random: rng,
          );

          if (format == lastFormat) {
            consecutiveCount++;
          } else {
            lastFormat = format;
            consecutiveCount = 1;
          }

          DistractorResult? distractorResult;
          if (format == QuestionFormat.multipleChoice) {
            distractorResult = DistractorGenerator.generate(
              target: repeatEntry,
              direction: dir,
              library: state.initialQueue,
              random: rng,
            );
          }

          questions.add(PracticeQuestion(
            entry: repeatEntry,
            direction: dir,
            format: format,
            isRepeat: true,
            distractorResult: distractorResult,
          ));
        }
      }
    }

    final isCompleted = nextIndex >= questions.length;

    state = state.copyWith(
      questions: questions,
      currentIndex: nextIndex,
      isRevealed: false,
      isSaving: false,
      saveError: null,
      firstPassPostSnapshots: postSnapshots,
      repeatQueue: repeatQueue,
      isCompleted: isCompleted,
      canOverride: canOverride,
      lastGradedEntryId: lastGradedId,
      selectedOptionIndex: null,
      answerCheckResult: null,
      typedText: null,
    );
  }
}
