---
name: file-issue
description: Write one issue as a newspaper article and file it on the project's tracker at once, without showing a draft or asking. Use when the user asks to file, open or create an issue, ticket or bug report for one piece of work. To only see the text, use draft-issue.
---

# File an Issue

Write the issue by the rules in
`${CLAUDE_SKILL_DIR}/../draft-issue/SKILL.md`, its Gather and Write
sections. Read that file first. Skip its Show section.

Then file it. Do not show a draft and do not ask for approval.

Resolve the tracker by reading
`${CLAUDE_SKILL_DIR}/../implement/references/resolve-config.md`. Its last resort, asking the
user, is the only question this skill asks. File the issue with operation T6 of
`${CLAUDE_SKILL_DIR}/../implement/references/trackers/{TRACKER}.md`, with the labels the user
named, or none.

Report the issue id or URL in one line.
