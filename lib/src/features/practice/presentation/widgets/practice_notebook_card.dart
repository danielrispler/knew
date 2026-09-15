import 'package:flutter/material.dart';
import '../../domain/practice_question.dart';

class PracticeNotebookCard extends StatefulWidget {
  final PracticeQuestion question;
  final bool isRevealed;
  final VoidCallback onTapReveal;

  const PracticeNotebookCard({
    super.key,
    required this.question,
    required this.isRevealed,
    required this.onTapReveal,
  });

  @override
  State<PracticeNotebookCard> createState() => _PracticeNotebookCardState();
}

class _PracticeNotebookCardState extends State<PracticeNotebookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _turnAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _turnAnimation = Tween<double>(begin: -0.24, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    if (widget.isRevealed) {
      _animController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PracticeNotebookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isRevealed && widget.isRevealed) {
      final disableAnimations = MediaQuery.disableAnimationsOf(context);
      if (disableAnimations) {
        _animController.value = 1.0;
      } else {
        _animController.forward(from: 0.0);
      }
    } else if (!widget.isRevealed) {
      _animController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.question.entry;
    final isEnglishPrompt = widget.question.direction == PromptDirection.englishToHebrew;

    final primaryText = isEnglishPrompt
        ? entry.english
        : entry.meanings
            .expand((m) => m.hebrewTranslations)
            .where((t) => t.trim().isNotEmpty)
            .join(', ');

    final isPhraseOrList = primaryText.contains(' ') || primaryText.contains(',');
    final primaryFontSize = isPhraseOrList ? 36.0 : 48.0;

    final firstMeaning = entry.meanings.isNotEmpty ? entry.meanings.first : null;
    final posText = firstMeaning?.partOfSpeech ?? '';
    final definitionText = firstMeaning?.definition ?? '';

    final revealedTranslations = entry.meanings
        .expand((m) => m.hebrewTranslations)
        .where((t) => t.trim().isNotEmpty)
        .join(', ');

    return GestureDetector(
      onTap: () {
        if (!widget.isRevealed) {
          widget.onTapReveal();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: isEnglishPrompt
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              const SizedBox(height: 32),
              // Main practiced term / prompt
              Text(
                primaryText,
                textDirection: isEnglishPrompt ? TextDirection.ltr : TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'FrankRuhlLibre',
                  fontWeight: FontWeight.w500,
                  fontSize: primaryFontSize,
                  color: theme.colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
              if (posText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  posText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (!widget.isRevealed) ...[
                Text(
                  isEnglishPrompt ? 'Tap to show answer' : 'לחץ להצגת התשובה',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (widget.isRevealed)
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_turnAnimation.value),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: isEnglishPrompt
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Divider(
                        color: theme.colorScheme.outlineVariant,
                        height: 32,
                        thickness: 1,
                      ),
                      // Revealed translation
                      Text(
                        isEnglishPrompt ? revealedTranslations : entry.english,
                        textDirection: isEnglishPrompt ? TextDirection.rtl : TextDirection.ltr,
                        style: TextStyle(
                          fontFamily: 'FrankRuhlLibre',
                          fontWeight: FontWeight.w400,
                          fontSize: 36,
                          color: theme.colorScheme.onSurface,
                          height: 1.3,
                        ),
                      ),
                      if (definitionText.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          definitionText,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 42),
            ],
          ),
        ),
      ),
    );
  }
}
