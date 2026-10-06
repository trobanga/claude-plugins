---
name: release-notes
description: Turn the pull requests merged since the last git tag into release notes grouped by GitHub label. Use when the user asks for release notes or a changelog.
---

1. Run `scripts/merged-prs.sh` to list the pull requests merged since the last tag. Done when every merged pull request is listed once.
2. Group them by label; a pull request without a label goes under "Other". Done when every pull request appears in exactly one group.
3. Write `RELEASE_NOTES.md` with one heading per group.
