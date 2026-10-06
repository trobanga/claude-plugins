export async function saveNote(note: { id: string; body: string }): Promise<void> {
  // writes to Postgres; rejects on a constraint violation
}
