# Gemini-assisted lookup UX & UI integration

Accepted 2026-09-15 for [#15](https://github.com/danielrispler/knew/issues/15), within [map #2](https://github.com/danielrispler/knew/issues/2).

This decision defines the interaction design and user experience for Gemini-assisted vocabulary lookup on the entry creation and editing screens, complementing the visual design rules in [visual-design.md](visual-design.md) and technical requirements in [gemini-api.md](../research/gemini-api.md).

## 1. Auto-Fetch Trigger & Typing Interaction

- **Trigger**: Typing in the term input field initiates an automatic Gemini lookup after a **600ms debounce** delay once the input contains at least 2 characters.
- **Progress Indicator**: A quiet linear progress indicator or subtle inline spinner displays directly below the term input field while the request is in flight.
- **Form Population**: Upon successful response (`valid: true`), meanings (part of speech, definition, Hebrew translations) auto-populate into editable form fields without replacing user-edited content.
- **Stale Request Cancellation**: If the user modifies the input while a lookup is in flight, the previous request cancellation/deadline token is invalidated and discarded.

## 2. Unrecognized Terms & Spelling Suggestions

- **Spelling Suggestion UI**: When Gemini returns `valid: false` with a non-null `suggestion` (e.g., "Did you mean *persistent*?"), an inline notebook banner is displayed directly beneath the term field.
- **Actions**:
  - Primary Action: Single-tap on the suggested word replaces the term field text and immediately triggers a fresh lookup for the suggestion.
  - Secondary Action: "Keep original term" dismisses the suggestion banner and leaves form fields available for manual entry.
- **No Suggestion Case**: When `valid: false` and `suggestion` is null, display a quiet inline banner: *"No suggestion found. You can enter the meanings manually below."*

## 3. Error Handling & Recovery

- **Inline Error Banners**: Transport or API errors (missing key, 429 quota exhaustion, 15s deadline timeout, invalid JSON response) do not block form usage. An inline notebook error banner displays the relevant human-friendly message from [gemini-api.md](../research/gemini-api.md).
- **Settings Navigation Link**: For key configuration errors (`API_KEY_INVALID`, missing key), the inline banner includes a direct link button: *"Configure API Key in Settings"*.
- **Manual Fallback**: In all error states, the user's typed term is preserved intact and all manual entry fields remain fully accessible for manual creation.

## 4. Text Direction & Hebrew Input Handling

- **Dynamic Script Detection**: The term input field dynamically auto-detects Hebrew characters (`TextDirection.rtl`) vs English characters (`TextDirection.ltr`) to align text correctly.
- **Target Concept Alignment**: Hebrew prompt inputs populate English as the target term in the entry model, returning distinct English alternatives per the Gemini lookup contract.
- **Manual Field Alignment**: Hebrew translation input fields strictly enforce `TextDirection.rtl` alignment.

## 5. Visual Integration (Notebook Theme)

- Adheres to Variant A (Plain Notebook): flat surface, Quiet divider (`#D9DEE7` light / `#333C4B` dark), and typography mappings defined in [visual-design.md](visual-design.md).
- Outlined action buttons enforce min 48px touch target height.
