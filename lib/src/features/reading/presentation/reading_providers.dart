import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knew/src/core/l10n/l10n.dart';

import '../data/claude_client.dart';

final claudeClientProvider = Provider<ClaudeClient>((ref) => ClaudeClient());

String claudeErrorMessage(AppLocalizations l10n, ClaudeErrorType type) =>
    switch (type) {
      ClaudeErrorType.missingKey => l10n.claudeErrorMissingKey,
      ClaudeErrorType.rejectedKey => l10n.claudeErrorRejectedKey,
      ClaudeErrorType.billing => l10n.claudeErrorBilling,
      ClaudeErrorType.rateLimited => l10n.claudeErrorRateLimited,
      ClaudeErrorType.rejectedRequest => l10n.claudeErrorRejectedRequest,
      ClaudeErrorType.unavailable => l10n.claudeErrorUnavailable,
      ClaudeErrorType.network => l10n.claudeErrorNetwork,
      ClaudeErrorType.timeout => l10n.claudeErrorTimeout,
      ClaudeErrorType.unusableResponse => l10n.claudeErrorUnusable,
    };
