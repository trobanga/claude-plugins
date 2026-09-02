---
name: idea
description: Capture an idea as a markdown file that reads like a newspaper article.
argument-hint: "What's the idea?"
disable-model-invocation: true
---

Write an idea to `ideas/<slug>.md` at the repo root.

Every idea solves a **problem**. That is the rule the rest of this skill serves: a file whose problem is vague describes a solution looking for a reason.

Write the file in the language the user described the idea in, translating the headings below to match.

## 1. Establish the problem

Interview the user until the problem can be stated in one sentence that names no solution.

Ask one question at a time, waiting for the answer before continuing — several at once is bewildering. Offer your recommended answer with each. Look facts up in the environment; put the decisions to the user.

Done when: the user has confirmed a one-sentence problem statement, and every section of the template can be filled from what they told you rather than from what you inferred.

## 2. Check for siblings

Read the ledes in `ideas/` for an idea attacking the same problem. Usually there are none — a problem with a competing idea is the rare and interesting case, so surface it when it happens and otherwise move on.

Done when: every file in `ideas/` has been checked.

## 3. Write the file

Structure it as an **inverted pyramid**. The lede carries the whole idea; each section below only deepens what has already been said. A reader who stops anywhere loses detail, never meaning — and finds nothing in the body the table of contents did not promise.

Little text. Cut every sentence the lede already made true.

```markdown
# <Idea title>

**Problem:** <one sentence, naming no solution>
**Idea:** <one sentence>

<Lede: one paragraph carrying problem, approach, and why it earns its cost.>

## Contents
- [Problem](#problem)
- [Idea](#idea)
- [Details](#details)

## Problem
<Who it hurts, when, and how much.>

## Idea
<How it solves that.>

## Details
<Only what a reader still going needs. Open questions live here.>
```

Done when: the file exists and the lede stands alone as the complete idea.

## 4. Link any siblings

Only when step 2 found one. Add an "Other ideas for this problem" list to the bottom of the new file and of each sibling, linking them to each other.

Done when: every sibling links to the new file and the new file links to every sibling.
