import 'package:flutter/material.dart';
import 'package:knew/src/core/l10n/l10n.dart';
import '../../domain/practice_question.dart';
import '../practice_session_state.dart';

class SentenceProductionPracticeWidget extends StatefulWidget {
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
  State<SentenceProductionPracticeWidget> createState() =>
      _SentenceProductionPracticeWidgetState();
}

class _SentenceProductionPracticeWidgetState
    extends State<SentenceProductionPracticeWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.text = widget.state.typedText ?? '';
  }

  @override
  void didUpdateWidget(covariant SentenceProductionPracticeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question != oldWidget.question) {
      widget.controller.text = widget.state.typedText ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final meaning =
        widget.question.entry.meanings[widget.question.meaningIndex!];
    final feedback = widget.state.sentenceEvaluation;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.sentenceProductionPrompt(
              widget.question.entry.english,
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            widget.question.entry.level == 5
                ? '${meaning.partOfSpeech} · ${meaning.hebrewTranslations.join(', ')}'
                : '${meaning.partOfSpeech} · ${meaning.definition}',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: widget.controller,
            enabled:
                !widget.state.isRevealed && !widget.state.isEvaluatingSentence,
            minLines: 3,
            maxLines: 6,
            textDirection: TextDirection.ltr,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: context.l10n.sentenceProductionHint,
            ),
          ),
          if (widget.state.isEvaluatingSentence)
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
                  Text(
                    context.l10n.targetTermFeedback(
                      feedback.usesTargetTerm ? '✓' : '✗',
                    ),
                  ),
                  Text(
                    context.l10n.meaningFeedback(
                      feedback.meaningCorrect ? '✓' : '✗',
                    ),
                  ),
                  Text(
                    context.l10n.grammarFeedback(
                      feedback.grammarCorrect ? '✓' : '✗',
                    ),
                  ),
                  Text(
                    context.l10n.naturalnessFeedback(
                      feedback.naturalUsage ? '✓' : '✗',
                    ),
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
