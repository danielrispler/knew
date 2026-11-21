# Claude suggests Chapter Words alongside Gemini

The learner reads books in English and wants each chapter's hard words before reading it. Gemini's free quota often drops the app to its weakest model, and the learner already pays for Claude. We added Claude as a second AI provider used only for the Reading feature: the learner sets a Reading (book and chapter) and Claude suggests Chapter Words for it. Gemini keeps lookup, Enrichment, sentence feedback, and Discover.

Consequences:
1. There are two API keys. The Claude key lives in its own secure-storage slot and is not exported.
2. Reading waits on AI, unlike Discover (ADR 0003). A chapter is fetched only when the learner asks, then cached in the `chapter_words` table, so a chapter is paid for once and reopens offline.
3. Chapter Words come from the model's memory of the book, not from book text. A word may belong to a nearby chapter. No quotes or plot are requested or stored.
4. Known is one list. Marking a Chapter Word Known writes to `suggested_words`, so Discover excludes it and backups already cover it. The Discovery Band is not affected.
5. A Chapter Word counts as learned once an Entry with the same key exists in the library.
6. Replacing Gemini with Claude everywhere was considered and deferred until Claude's quality and cost are known from this feature.
