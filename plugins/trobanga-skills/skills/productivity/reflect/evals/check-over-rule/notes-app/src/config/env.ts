const bases: Record<string, string> = {
  production: "https://api.notes.example",
  staging: "https://staging-api.notes.example",
  development: "http://localhost:8080",
};

export const apiBase = bases[process.env.NODE_ENV ?? "development"];
