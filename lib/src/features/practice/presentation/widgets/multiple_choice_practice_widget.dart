import 'package:flutter/material.dart';
import 'package:knew/src/core/l10n/l10n.dart';
import '../../domain/practice_question.dart';
import '../practice_session_state.dart';

class MultipleChoicePracticeWidget extends StatelessWidget {
  final PracticeQuestion question;
  final PracticeSessionState state;
  final ValueChanged<int> onSelectOption;

  const MultipleChoicePracticeWidget({
    super.key,
    required this.question,
    required this.state,
    required this.onSelectOption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = question.entry;
    final distractorResult = question.distractorResult;

    if (distractorResult == null || !distractorResult.isAvailable) {
      return Center(child: Text(context.l10n.multipleChoiceUnavailable));
    }

    final isEngToHeb = question.direction == PromptDirection.englishToHebrew;
    final promptText = isEngToHeb
        ? entry.english
        : entry.meanings.first.hebrewTranslations.join(', ');
    final options = distractorResult.options;
    final correctIndex = distractorResult.correctOptionIndex;
    final selectedIndex = state.selectedOptionIndex;
    final isRevealed = state.isRevealed;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Prompt Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Text(
                    promptText,
                    textDirection: isEngToHeb
                        ? TextDirection.ltr
                        : TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontFamily: isEngToHeb ? 'FrankRuhlLibre' : null,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                isEngToHeb
                    ? context.l10n.selectHebrewTranslation
                    : context.l10n.selectEnglishTerm,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Options list
              ...List.generate(options.length, (index) {
                final optionText = options[index];
                final isCorrectOption = (index == correctIndex);
                final isSelectedOption = (index == selectedIndex);

                Color? backgroundColor;
                Color borderColor = theme.colorScheme.outlineVariant;
                IconData? statusIcon;
                Color iconColor = theme.colorScheme.onSurface;

                if (isRevealed) {
                  if (isCorrectOption) {
                    backgroundColor = Colors.green.withOpacity(0.12);
                    borderColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    iconColor = Colors.green;
                  } else if (isSelectedOption && !isCorrectOption) {
                    backgroundColor = Colors.red.withOpacity(0.12);
                    borderColor = Colors.red;
                    statusIcon = Icons.cancel;
                    iconColor = Colors.red;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: OutlinedButton(
                    onPressed: isRevealed ? null : () => onSelectOption(index),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: backgroundColor,
                      side: BorderSide(
                        color: borderColor,
                        width:
                            isRevealed && (isCorrectOption || isSelectedOption)
                            ? 2
                            : 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      minimumSize: const Size.fromHeight(56),
                      alignment: isEngToHeb
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            optionText,
                            textDirection: isEngToHeb
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            textAlign: isEngToHeb
                                ? TextAlign.start
                                : TextAlign.start,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontFamily: !isEngToHeb ? 'FrankRuhlLibre' : null,
                              color: theme.colorScheme.onSurface,
                              fontWeight: isSelectedOption
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (statusIcon != null) ...[
                          const SizedBox(width: 12),
                          Icon(statusIcon, color: iconColor, size: 22),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
