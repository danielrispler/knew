# Gemini model catalog & automatic rate-limit fallback

Accepted 2026-09-15 for Gemini model catalog accuracy and rate-limit resiliency.

## Context

The Gemini API quota and model availability vary by model tier and Google AI Studio project limits. To maximize availability and output quality, the application requires an accurate model catalog starting from the highest performance tier down to the baseline lite tier, as well as an automatic fallback policy when encountering rate limits or model errors.

## Model Catalog

The application catalog defines the following Gemini Flash models in descending performance order:

1. `gemini-3.8-flash` (Default primary model)
2. `gemini-3.7-flash`
3. `gemini-3.6-flash`
4. `gemini-3.5-flash`
5. `gemini-3.5-flash-lite` (Baseline Lite model)

## Fallback Policy

1. **Triggering Conditions**:
   - HTTP 429 (`RESOURCE_EXHAUSTED` / Quota & Rate Limit)
   - HTTP 404 (`NOT_FOUND` / Model Unavailable or Deprecated)
   - HTTP 500 / 503 (`INTERNAL` / `UNAVAILABLE` Temporary Server Errors)
   - Request Timeout (15-second client deadline)

2. **Non-Fallback Conditions**:
   - HTTP 400 / 401 / 403 Invalid API key or permission errors stop execution immediately to alert the user to check their key in Settings.

3. **Fallback Sequence & Custom Models**:
   - Lookups start at the user's selected primary model (defaulting to `gemini-3.8-flash`).
   - **Custom Model Name Support**: Users may select "Custom Model..." in Settings and enter an arbitrary Gemini model identifier (e.g. `gemini-1.5-pro` or tuned model resource name). The custom model will be attempted first; if it encounters a rate limit or 404 error, lookups fall back to the standard catalog sequence (`gemini-3.8-flash` → `gemini-3.7-flash` → ...).
   - If a fallback-eligible error occurs, the lookup automatically retries silently with the next model down the catalog sequence until a response is received or all models are exhausted.
   - Fallbacks operate silently to prioritize user experience and UI speed. If all models in the chain fail, the error message from the final attempt is presented in the UI.
