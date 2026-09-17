import 'package:flutter/material.dart';
import 'package:knew/src/core/l10n/l10n.dart';
import '../../domain/practice_question.dart';
import '../practice_session_state.dart';

class SentenceProductionPracticeWidget extends StatelessWidget {
  final PracticeQuestion question;
  final PracticeSessionState state;
  final TextEditingController controller;
  const SentenceProductionPracticeWidget({
    super.key,
    required this.question,
    required this.state,
    required this.controller,
  });
  @override
  Widget build(BuildContext context) {
    final meaning = question.entry.meanings[question.meaningIndex!];
    final feedback = state.sentenceEvaluation;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.sentenceProductionPrompt(question.entry.english),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            question.entry.level == 5
                ? '${meaning.partOfSpeech} · ${meaning.hebrewTranslations.join(', ')}'
                : '${meaning.partOfSpeech} · ${meaning.definition}',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            enabled: !state.isRevealed && !state.isEvaluatingSentence,
            minLines: 3,
            maxLines: 6,
            textDirection: TextDirection.ltr,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: context.l10n.sentenceProductionHint,
            ),
          ),
          if (state.isEvaluatingSentence)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (feedback != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target term: ${feedback.usesTargetTerm ? '✓' : '✗'}'),
                  Text('Meaning: ${feedback.meaningCorrect ? '✓' : '✗'}'),
                  Text('Grammar: ${feedback.grammarCorrect ? '✓' : '✗'}'),
                  Text(
                    'Naturalness (feedback only): ${feedback.naturalUsage ? '✓' : '✗'}',
                  ),
                  const SizedBox(height: 8),
                  Text(feedback.feedback),
                ],
              ),
            ),
          if (feedback?.suggestedImprovement case final suggestion?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(suggestion),
            ),
        ],
      ),
    );
  }
}
