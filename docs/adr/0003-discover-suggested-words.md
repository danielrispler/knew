# Discover Suggested Words Architecture

We needed an opt-in discovery mechanism for unfamiliar high-frequency English words without imposing cognitive burden or requiring a separate proficiency test. We decided on a hybrid candidate architecture: a bundled, read-only frequency-ranked asset (~2,800 words, e.g. NGSL) serves as the primary source, supplemented by a non-blocking background queue of Gemini-personalized suggestions.

Batches of 5 are presented on a dedicated Discover screen (1 easier probe, 2 target window, 1 harder probe, 1 Gemini suggestion with full local fallback). The target difficulty window adapts dynamically using a continuous sliding Discovery Band center rank stored in settings, shifting based on user actions (Learn, Known, Skip).

To keep the screen fast and reliable:
1. The Candidate Pool is an in-memory asset rather than a seeded SQLite table, avoiding database migrations for word list updates.
2. Active batch state, skip history, and known exclusions live in a unified `suggested_words` SQLite table.
3. Discover never blocks on AI: Gemini suggestions are prefetched into a local queue, falling back immediately to the bundled pool if the queue is empty or Gemini is offline.
4. Word meanings are hidden by default with an on-demand reveal to preserve the self-assessment signal, and the `revealed_before_action` state is captured to weight band adaptation.
5. Known words and the Discovery Band center are included in backup exports to prevent re-suggesting known words after device restoration.
