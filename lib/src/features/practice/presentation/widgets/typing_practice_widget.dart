import 'package:flutter/material.dart';
import 'package:knew/src/core/l10n/l10n.dart';
import '../../domain/answer_checker.dart';
import '../../domain/practice_question.dart';
import '../practice_session_state.dart';

class TypingPracticeWidget extends StatefulWidget {
  final PracticeQuestion question;
  final PracticeSessionState state;
  final TextEditingController textController;
  final ValueChanged<String> onSubmit;

  const TypingPracticeWidget({
    super.key,
    required this.question,
    required this.state,
    required this.textController,
    required this.onSubmit,
  });

  @override
  State<TypingPracticeWidget> createState() => _TypingPracticeWidgetState();
}

class _TypingPracticeWidgetState extends State<TypingPracticeWidget> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant TypingPracticeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.question != oldWidget.question) {
      widget.textController.text = widget.state.typedText ?? '';
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = widget.question;
    final entry = question.entry;
    final isEngToHeb = question.direction == PromptDirection.englishToHebrew;
    final expectsHebrew = isEngToHeb;
    final isRevealed = widget.state.isRevealed;
    final checkResult = widget.state.answerCheckResult;

    final promptText = isEngToHeb
        ? entry.english
        : entry.meanings.first.hebrewTranslations.join(', ');

    final answerDirection = expectsHebrew ? TextDirection.rtl : TextDirection.ltr;

    final expectedTargetString = isEngToHeb
        ? entry.meanings.first.hebrewTranslations.join(', ')
        : entry.english;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Prompt
              Container(
                padding: const EdgeInsets.all(24.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  promptText,
                  textDirection: isEngToHeb ? TextDirection.ltr : TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontFamily: isEngToHeb ? 'FrankRuhlLibre' : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // TextField
              TextField(
                controller: widget.textController,
                focusNode: _focusNode,
                enabled: !isRevealed,
                textDirection: answerDirection,
                textAlign: TextAlign.start,
                keyboardType: TextInputType.text,
                hintLocales: [expectsHebrew ? const Locale('he') : const Locale('en', 'US')],
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.done,
                onChanged: (val) {
                  // Keep controller input text in sync
                },
                onSubmitted: isRevealed ? null : widget.onSubmit,
                decoration: InputDecoration(
                  labelText: expectsHebrew ? context.l10n.typeAnswerInHebrew : context.l10n.typeAnswerInEnglish,
                  hintText: expectsHebrew ? context.l10n.typeHebrewHint : context.l10n.typeEnglishHint,
                  hintTextDirection: answerDirection,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Feedback Banner when revealed
              if (isRevealed && checkResult != null) ...[
                if (checkResult.status == AnswerCheckStatus.exactMatch)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Exact match!',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (checkResult.status == AnswerCheckStatus.typoMatch)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade800),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade900),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Correct (typo: expected "${checkResult.matchedTarget ?? expectedTargetString}")',
                            style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (checkResult.status == AnswerCheckStatus.noMatch)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Incorrect. Expected: "$expectedTargetString"',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
