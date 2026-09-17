# Gemini model catalog & direct rate-limit fallback

Updated 2026-09-17 for fast lookups, direct Flash-Lite fallback, and low-latency API configuration.

## Context

The user's Gemini free-plan quota for the preferred primary model is limited, while significantly more quota is available for `gemini-3.5-flash-lite`. Attempting multiple intermediate models sequentially caused 6–10 second latency waterfalls. To achieve near-instant lookups (~600ms–1s), lookups must execute the primary model with zero thinking budget, avoid intermediate retries, and fall back immediately to `gemini-3.5-flash-lite`.

## Model Fallback Sequence

1. **Primary Model**: User's selected model (default: `gemini-3.8-flash`).
2. **Direct Fallback**: `gemini-3.5-flash-lite`.
3. **Sequence Resolution**:
   - If the primary model is anything other than `gemini-3.5-flash-lite`, the sequence is exactly two attempts: `[primaryModel, gemini-3.5-flash-lite]`.
   - If the user explicitly sets `gemini-3.5-flash-lite` as their primary model, the sequence is a single attempt: `[gemini-3.5-flash-lite]`.
   - Intermediate model attempts are eliminated.

## Latency & Generation Optimization

1. **Thinking Budget**:
   - For the primary model, send `"thinkingConfig": {"thinkingBudget": 0}` (or lowest supported budget) to disable internal reasoning loops that otherwise add 4–8 seconds of token generation delay.
   - For `gemini-3.5-flash-lite`, omit `thinkingConfig` entirely because Flash-Lite does not support reasoning configuration and will reject the request with HTTP 400.
2. **Token Ceiling**:
   - Set `maxOutputTokens: 512` (reduced from 4096) to reflect concise vocabulary entries and prevent decoding overruns.
3. **Structured Schema**:
   - Retain full `responseJsonSchema` ensuring type safety for part of speech, definitions, and Hebrew translations.
4. **Attempt Timing & Observability**:
   - Log structured metrics for every model attempt (`model`, `durationMs`, `httpStatus`, `outcome`) to console/developer logs to verify where latency occurs.

## Fallback Conditions

1. **Triggering Conditions (Direct Fallback to Flash-Lite)**:
   - HTTP 429 (`RESOURCE_EXHAUSTED` / Quota & Rate Limit)
   - HTTP 404 (`NOT_FOUND` / Model Unavailable or Deprecated)
   - HTTP 500 / 503 (`INTERNAL` / `UNAVAILABLE` Server Errors)
   - Request Timeout (15-second client deadline)

2. **Non-Fallback Conditions**:
   - HTTP 400 / 401 / 403 Invalid API key or permission errors stop execution immediately to prompt the user to check their key in Settings.

