---
name: file-issue
description: Write one issue as a newspaper article and file it on the project's tracker at once, without showing a draft or asking. Use when the user asks to file, open or create an issue, ticket or bug report for one piece of work. To only see the text, use draft-issue.
---

# File an Issue

Write the issue by the rules in
`${CLAUDE_PLUGIN_ROOT}/skills/engineering/draft-issue/SKILL.md`, sections 1 and 2. Read that
file first. Skip its section 3.

Then file it. Do not show a draft and do not ask for approval.

The tracker is recorded in `.agents/issue-tracker.md`, `.agents/issue-tracker.local.md`, or
as prose in `CLAUDE.md`. If none of them says, ask which tracker to use, and offer
`Skill(trobanga-skills:setup-project)` to record the answer. That is the only question this
skill asks.

Report the issue id or URL in one line.
