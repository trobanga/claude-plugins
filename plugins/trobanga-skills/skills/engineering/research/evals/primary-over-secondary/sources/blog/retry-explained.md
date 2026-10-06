# httpretry explained (community blog, 2023)

I've been using httpretry for a while, here's the cheat sheet:

- `retry(call)` tries **3 times** by default.
- Backoff doubles each time and tops out at **60 seconds**.
- It retries on any exception, so wrap carefully.

Hope this helps!
