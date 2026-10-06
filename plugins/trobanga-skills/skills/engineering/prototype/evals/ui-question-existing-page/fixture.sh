#!/usr/bin/env bash
# Builds a minimal Next.js (app router) project with an existing, cluttered
# settings page that fetches its own data. No dependencies are installed.
set -euo pipefail

mkdir -p app/settings app/loans components lib

cat > package.json <<'EOF'
{
  "name": "toolshed-web",
  "private": true,
  "scripts": { "dev": "next dev", "build": "next build" },
  "dependencies": { "next": "15.0.0", "react": "19.0.0", "react-dom": "19.0.0" }
}
EOF

cat > app/layout.tsx <<'EOF'
import { Sidebar } from "@/components/Sidebar";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="flex">
        <Sidebar />
        <main className="flex-1 p-6">{children}</main>
      </body>
    </html>
  );
}
EOF

cat > components/Sidebar.tsx <<'EOF'
export function Sidebar() {
  return (
    <nav className="w-48 border-r p-4">
      <a href="/loans">Loans</a>
      <a href="/settings">Settings</a>
    </nav>
  );
}
EOF

cat > lib/settings.ts <<'EOF'
export type MemberSettings = {
  name: string;
  email: string;
  phone: string;
  reminderDaysBefore: number;
  remindBy: "email" | "sms" | "both";
  homeBranch: string;
  newsletter: boolean;
  shareHistoryWithBranch: boolean;
};

export async function getSettings(): Promise<MemberSettings> {
  return {
    name: "Ada Lovelace", email: "ada@example.com", phone: "+49 30 1234567",
    reminderDaysBefore: 2, remindBy: "email", homeBranch: "Kreuzberg",
    newsletter: false, shareHistoryWithBranch: true,
  };
}
EOF

cat > app/settings/page.tsx <<'EOF'
import { getSettings } from "@/lib/settings";

export default async function SettingsPage() {
  const s = await getSettings();
  return (
    <div>
      <h1>Settings</h1>
      <label>Name <input defaultValue={s.name} /></label>
      <label>Email <input defaultValue={s.email} /></label>
      <label>Phone <input defaultValue={s.phone} /></label>
      <label>Remind me days before due <input type="number" defaultValue={s.reminderDaysBefore} /></label>
      <label>Remind by <select defaultValue={s.remindBy}><option>email</option><option>sms</option><option>both</option></select></label>
      <label>Home branch <input defaultValue={s.homeBranch} /></label>
      <label><input type="checkbox" defaultChecked={s.newsletter} /> Newsletter</label>
      <label><input type="checkbox" defaultChecked={s.shareHistoryWithBranch} /> Share loan history with my branch</label>
      <button>Save</button>
    </div>
  );
}
EOF

cat > app/loans/page.tsx <<'EOF'
export default function LoansPage() {
  return <h1>Loans</h1>;
}
EOF
