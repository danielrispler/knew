# Keep vocabulary on this device

On 2026-09-15, the user confirmed that knew is for this phone and local storage is sufficient; online-only operation would also be acceptable. Use SQLite as the vocabulary store, with manual versioned export/import for backup. Practice works from local data, although offline operation is no longer a user requirement. Supabase was considered for remote storage, but backup across devices and synchronization are not required for this version, so they do not justify adding authentication or synchronization.
