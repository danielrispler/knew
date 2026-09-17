# Gemini-assisted lookup UX & UI integration

Updated 2026-09-17 based on Prototype 1 (Instant AI Card) redesign for streamlined, low-friction vocabulary capture.

This decision defines the interaction design and user experience for Gemini-assisted vocabulary lookup on the entry creation and editing screens, complementing the visual design rules in [visual-design.md](visual-design.md) and technical requirements in [gemini-api.md](../research/gemini-api.md).

## 1. Hero Term Input & Typing Interaction

- **Hero Term Field**: The English term input is the primary, prominent hero element at the top of the screen with clear button (`✕`) and keyboard Enter/Done action.
- **Trigger**: Typing initiates an automatic Gemini lookup after a **600ms debounce** delay once the input contains at least 2 characters. Pressing keyboard Search/Done triggers immediately without waiting for the timer.
- **Progress Indicator**: A subtle inline loading indicator/shimmer renders in the card area while lookup is in flight.
- **Stale Request Cancellation**: Modifying the input while a lookup is in flight cancels prior pending requests.

## 2. Instant AI Review Card (Prototype 1)

- **Default Layout**: Renders directly below the hero term field upon lookup completion:
  - **Header**: Term display, phonetic pronunciation, and Part of Speech chip.
  - **Multiple Meanings / Senses**: If Gemini returns >1 meaning, sense switcher chips (`1: Verb`, `2: Noun`) allow switching between senses.
  - **Hebrew Translation Chips (RTL)**: All returned translations render as interactive chips with the primary translation pre-selected. Tapping toggles selection so users control which translations are saved.
  - **Definition Box**: Clean English definition card with primary color left accent border.
- **Primary Save Action**: A thumb-friendly full-width floating bottom button: **"Save to Library"**. Tapping saves the entry and returns to the vocabulary list.

## 3. Secondary & Custom Fields (Collapsible Drawer)

- **New Entries**: Custom and manual fields (`Source`, `Context / Sentence`, manual meaning overrides) are placed in a collapsible drawer labeled *"Need custom meaning or notes? ▾"*, **collapsed by default**.
- **Existing Entries**: When editing an existing entry with attached source, context, or custom meanings, the drawer **auto-expands** so existing details are immediately editable.
- **Offline & Error States**: If a network failure or invalid API key occurs, the drawer **auto-expands** so manual entry fields are immediately accessible without blocking the user.

## 4. Unrecognized Terms & Spelling Suggestions

- **Spelling Suggestion UI**: When Gemini returns `valid: false` with a non-null `suggestion` (e.g., *"Did you mean persistent?"*), an inline chip is displayed beneath the hero input. Single-tap replaces the term and immediately triggers a fresh lookup.
- **No Suggestion Case**: Displays quiet inline banner: *"No suggestion found. You can enter meanings manually below"* and unfolds the custom fields drawer.

## 5. Text Direction & Hebrew Handling

- **Dynamic Script Detection**: The term field auto-detects Hebrew characters (`TextDirection.rtl`) vs English (`TextDirection.ltr`).
- **Translation RTL Alignment**: Hebrew chips and Hebrew manual input fields strictly enforce `TextDirection.rtl`.

