import { apiBase } from "./config/env";

export async function search(query: string) {
  const res = await fetch(`${apiBase}/search?q=${encodeURIComponent(query)}`);
  return res.json();
}
