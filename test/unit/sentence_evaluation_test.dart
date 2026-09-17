import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/practice/domain/sentence_evaluation.dart';
import 'package:knew/src/features/practice/domain/practice_scheduler.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';

void main() {
  test('target detector respects token boundaries, inflections, and phrases', () {
    expect(SentenceTargetDetector.containsTarget(sentence: 'She put up with it.', forms: ['put up with']), isTrue);
    expect(SentenceTargetDetector.containsTarget(sentence: 'He runs daily.', forms: ['run', 'runs']), isTrue);
    expect(SentenceTargetDetector.containsTarget(sentence: 'The runner arrived.', forms: ['run']), isFalse);
  });

  test('sentence invalid keeps level and schedules tomorrow', () {
    final entry = Entry.create(id: 'id', english: 'run', meanings: const [Meaning(partOfSpeech: 'verb', definition: 'move fast', hebrewTranslations: ['לרוץ'])], level: 5, dueDate: '2026-01-01');
    final graded = PracticeScheduler.gradeSentenceIncorrect(entry, now: DateTime(2026, 1, 10, 12));
    expect(graded.level, 5);
    expect(graded.timesWrong, 1);
    expect(graded.dueDate, '2026-01-11');
  });
}
