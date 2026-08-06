# Prefer MusicKit on iOS when it can do the job

On iOS, Catalog, Auth, Playback, and Recommendations (when MusicKit can serve them) use **native MusicKit**. REST is only for gaps: writes, charts, relationships, pagination parity where MusicKit cannot match Android/web, and id-filtered recommendation fetches.

Do **not** “parity-fix” Catalog get-by-id, Auth, or Playback onto REST to shrink mappers or unify transports. Android/web stay REST-for-data + native/MusicKit JS for Auth/Playback; that is intentional, not a reason to move iOS off MusicKit.

See [PLATFORM_IMPLEMENTATION.md](../PLATFORM_IMPLEMENTATION.md), [CONTEXT.md](../../CONTEXT.md).
