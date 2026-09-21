# Keep captured terms in a durable foreground queue

Quick capture stores a Pending Entry locally before Gemini lookup. The app processes pending entries one at a time while active and resumes after restart. This avoids unreliable platform background jobs while ensuring a captured Term is never lost. Pending and Failed Entries are excluded from practice; successful lookup makes an Entry ready immediately.
