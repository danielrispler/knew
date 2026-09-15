import 'package:flutter/material.dart';
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
      return const Center(child: Text('Multiple Choice unavailable'));
    }

    final isEngToHeb = question.direction == PromptDirection.englishToHebrew;
    final promptText = isEngToHeb ? entry.english : entry.meanings.first.hebrewTranslations.join(', ');
    final options = distractorResult.options;
    final correctIndex = distractorResult.correctOptionIndex;
    final selectedIndex = state.selectedOptionIndex;
    final isRevealed = state.isRevealed;

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
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
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

              Text(
                isEngToHeb ? 'Select the correct Hebrew translation:' : 'Select the correct English term:',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                    backgroundColor = Colors.green.withValues(alpha: 0.15);
                    borderColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    iconColor = Colors.green;
                  } else if (isSelectedOption && !isCorrectOption) {
                    backgroundColor = Colors.red.withValues(alpha: 0.15);
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
                      side: BorderSide(color: borderColor, width: isRevealed && (isCorrectOption || isSelectedOption) ? 2 : 1),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      minimumSize: const Size.fromHeight(52),
                      alignment: isEngToHeb ? Alignment.centerRight : Alignment.centerLeft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            optionText,
                            textDirection: isEngToHeb ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: isEngToHeb ? TextAlign.start : TextAlign.start,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontFamily: !isEngToHeb ? 'FrankRuhlLibre' : null,
                              color: theme.colorScheme.onSurface,
                              fontWeight: isSelectedOption ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (statusIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(statusIcon, color: iconColor, size: 20),
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
