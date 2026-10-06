# Plan: move sessions to Redis

Session lookups are the slowest query on the checkout path. Move session
storage to Redis next sprint, then drop the old store.

1. Add a Redis service.
2. Switch the session middleware to Redis.
3. Delete the old session storage.
