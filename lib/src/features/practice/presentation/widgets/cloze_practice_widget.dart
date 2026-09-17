import 'package:flutter/material.dart';
import '../../domain/practice_question.dart';
import '../practice_session_state.dart';

class ClozePracticeWidget extends StatefulWidget {
  final PracticeQuestion question;
  final PracticeSessionState state;
  final ValueChanged<String> onSubmit;
  final VoidCallback onHint;
  final VoidCallback onConfirmTypo;
  final VoidCallback onShowAnswer;
  const ClozePracticeWidget({super.key, required this.question, required this.state, required this.onSubmit, required this.onHint, required this.onConfirmTypo, required this.onShowAnswer});

  @override
  State<ClozePracticeWidget> createState() => _ClozePracticeWidgetState();
}

class _ClozePracticeWidgetState extends State<ClozePracticeWidget> {
  final _controller = TextEditingController();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final example = widget.question.exampleUsage!;
    final meaning = widget.question.entry.meanings[widget.question.meaningIndex!];
    final level = widget.question.entry.level;
    if (_controller.text != (widget.state.typedText ?? '')) {
      _controller.text = widget.state.typedText ?? '';
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(level == 3 ? meaning.hebrewTranslations.join(', ') : meaning.definition,
            textDirection: level == 3 ? TextDirection.rtl : TextDirection.ltr,
            style: Theme.of(context).textTheme.titleLarge),
        Text(meaning.partOfSpeech, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 28),
        Directionality(textDirection: TextDirection.ltr, child: Text(example.clozeSentence, style: Theme.of(context).textTheme.headlineSmall)),
        const SizedBox(height: 24),
        TextField(controller: _controller, enabled: !widget.state.isRevealed,
          textDirection: TextDirection.ltr, autocorrect: false, enableSuggestions: false,
          onSubmitted: widget.onSubmit,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Fill in the blank')),
        if (!widget.state.isRevealed) ...[
          const SizedBox(height: 16),
          FilledButton(onPressed: () => widget.onSubmit(_controller.text), child: const Text('Check answer')),
          TextButton(onPressed: widget.onHint, child: const Text('Show first letter')),
          TextButton(onPressed: widget.onShowAnswer, child: const Text('Show answer')),
        ],
        if (widget.state.isRevealed) ...[
          const SizedBox(height: 16),
          Directionality(textDirection: TextDirection.ltr, child: Text('Answer: ${example.target}')),
          if (widget.state.canConfirmTypo)
            FilledButton(onPressed: widget.onConfirmTypo, child: const Text('Count as correct (typo)')),
        ],
      ]),
    );
  }
}
