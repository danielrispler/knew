import '../../vocabulary/domain/entry.dart';
import '../domain/answer_checker.dart';
import '../domain/practice_question.dart';

class StageMovement {
  final Entry entry;
  final Stage fromStage;
  final Stage toStage;

  const StageMovement({
    required this.entry,
    required this.fromStage,
    required this.toStage,
  });
}

class PracticeSessionState {
  static const Object _unset = Object();
  final List<Entry> initialQueue;
  final List<PracticeQuestion> questions;
  final int currentIndex;
  final bool isRevealed;
  final bool isExtraPractice;
  final bool isSaving;
  final String? saveError;
  final bool? lastAttemptedGrade;
  final Map<String, Entry> firstPassPreSnapshots;
  final Map<String, Entry> firstPassPostSnapshots;
  final List<Entry> repeatQueue;
  final bool isCompleted;
  final bool canOverride;
  final String? lastGradedEntryId;

  // New fields for multiple choice and typing formats
  final int? selectedOptionIndex;
  final AnswerCheckResult? answerCheckResult;
  final String? typedText;
  final bool isAssisted;
  final bool canConfirmTypo;

  const PracticeSessionState({
    this.initialQueue = const [],
    this.questions = const [],
    this.currentIndex = 0,
    this.isRevealed = false,
    this.isExtraPractice = false,
    this.isSaving = false,
    this.saveError,
    this.lastAttemptedGrade,
    this.firstPassPreSnapshots = const {},
    this.firstPassPostSnapshots = const {},
    this.repeatQueue = const [],
    this.isCompleted = false,
    this.canOverride = false,
    this.lastGradedEntryId,
    this.selectedOptionIndex,
    this.answerCheckResult,
    this.typedText,
    this.isAssisted = false,
    this.canConfirmTypo = false,
  });

  PracticeQuestion? get currentQuestion {
    if (currentIndex >= 0 && currentIndex < questions.length) {
      return questions[currentIndex];
    }
    return null;
  }

  int get totalMainQuestions => questions.where((q) => !q.isRepeat).length;

  int get reviewedCount => firstPassPostSnapshots.length;

  double get accuracy {
    if (reviewedCount == 0) return 0.0;
    int correctCount = 0;
    for (final entry in firstPassPostSnapshots.values) {
      final pre = firstPassPreSnapshots[entry.id];
      if (pre != null) {
        if (entry.level > pre.level ||
            (pre.level == 6 &&
                entry.level == 6 &&
                entry.timesCorrect > pre.timesCorrect)) {
          correctCount++;
        }
      }
    }
    return correctCount / reviewedCount;
  }

  List<StageMovement> get stageMovements {
    if (isExtraPractice) return const [];
    final movements = <StageMovement>[];
    for (final postEntry in firstPassPostSnapshots.values) {
      final preEntry = firstPassPreSnapshots[postEntry.id];
      if (preEntry != null) {
        final fromStage = preEntry.stage;
        final toStage = postEntry.stage;
        if (fromStage != toStage) {
          movements.add(
            StageMovement(
              entry: postEntry,
              fromStage: fromStage,
              toStage: toStage,
            ),
          );
        }
      }
    }
    return movements;
  }

  PracticeSessionState copyWith({
    List<Entry>? initialQueue,
    List<PracticeQuestion>? questions,
    int? currentIndex,
    bool? isRevealed,
    bool? isExtraPractice,
    bool? isSaving,
    Object? saveError = _unset,
    Object? lastAttemptedGrade = _unset,
    Map<String, Entry>? firstPassPreSnapshots,
    Map<String, Entry>? firstPassPostSnapshots,
    List<Entry>? repeatQueue,
    bool? isCompleted,
    bool? canOverride,
    Object? lastGradedEntryId = _unset,
    Object? selectedOptionIndex = _unset,
    Object? answerCheckResult = _unset,
    Object? typedText = _unset,
    bool? isAssisted,
    bool? canConfirmTypo,
  }) {
    return PracticeSessionState(
      initialQueue: initialQueue ?? this.initialQueue,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      isRevealed: isRevealed ?? this.isRevealed,
      isExtraPractice: isExtraPractice ?? this.isExtraPractice,
      isSaving: isSaving ?? this.isSaving,
      saveError: identical(saveError, _unset)
          ? this.saveError
          : saveError as String?,
      lastAttemptedGrade: identical(lastAttemptedGrade, _unset)
          ? this.lastAttemptedGrade
          : lastAttemptedGrade as bool?,
      firstPassPreSnapshots:
          firstPassPreSnapshots ?? this.firstPassPreSnapshots,
      firstPassPostSnapshots:
          firstPassPostSnapshots ?? this.firstPassPostSnapshots,
      repeatQueue: repeatQueue ?? this.repeatQueue,
      isCompleted: isCompleted ?? this.isCompleted,
      canOverride: canOverride ?? this.canOverride,
      lastGradedEntryId: identical(lastGradedEntryId, _unset)
          ? this.lastGradedEntryId
          : lastGradedEntryId as String?,
      selectedOptionIndex: identical(selectedOptionIndex, _unset)
          ? this.selectedOptionIndex
          : selectedOptionIndex as int?,
      answerCheckResult: identical(answerCheckResult, _unset)
          ? this.answerCheckResult
          : answerCheckResult as AnswerCheckResult?,
      typedText: identical(typedText, _unset)
          ? this.typedText
          : typedText as String?,
      isAssisted: isAssisted ?? this.isAssisted,
      canConfirmTypo: canConfirmTypo ?? this.canConfirmTypo,
    );
  }
}
