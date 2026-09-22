---
name: draft-issue
description: Draft one issue as a newspaper article, the important part first in plain language, then the details an AI needs to implement it, in as few words as possible. Shows the text and files nothing. Use when the user asks to write or draft an issue, ticket or bug report for one piece of work. To file it directly, use file-issue.
---

# Draft an Issue

An issue is a newspaper article. A reader who stops after the first paragraph knows what
changes and why. A reader who continues gets what the implementation needs, and nothing more.

## 1. Gather

Work from the conversation. If the user gives a reference (file, issue, URL), read it.
Do not explore the codebase beyond what the details section needs.

## 2. Write

Use the template. Every sentence must change what the implementer does. If it does not, delete it.

<template>

# <Headline: what changes, as a verb phrase. Under 10 words.>

<Lede: one paragraph, at most three sentences, readable by an 18-year-old with no context.
What is wrong or missing, what the change makes possible, and why it matters now.
No code identifiers, no file paths.>

## Details

<For the implementing agent. Only facts it cannot derive from the code: the current
behaviour, the wanted behaviour, constraints, decisions already made, and traps found in the
discussion. Bullets. Name a file, function or flag only when the agent has to go there.>

## Done when

- [ ] <One checkable criterion per line, in the user's terms, not the code's.>

</template>

Rules:

- Lede before everything. Never open with background.
- No motivation prose after the lede. The lede holds all of the why.
- No implementation plan. The agent that picks the issue up designs the change.
- No repetition between sections. A fact appears once, in the earliest section it fits.
- Target: whole issue under 150 words. Cut until it hurts, then stop.

<example>

# Reject uploads over the plan's storage limit

Users on the free plan can upload past their 1 GB limit. The server accepts the file,
then the account is locked until support deletes it. The limit must stop the upload before
any byte is stored.

## Details

- The check exists for the quota shown in the UI, but the upload endpoint does not call it.
- Reject with HTTP 413 and the message the UI already renders for quota errors.
- Chunked uploads: check the declared total size on the first chunk, not per chunk.

## Done when

- [ ] An upload that would exceed the limit is refused before storage is written.
- [ ] The user sees the existing quota message.
- [ ] Uploads under the limit still work, chunked and single.

</example>

## 3. Show

Show the draft. Do not file it.
