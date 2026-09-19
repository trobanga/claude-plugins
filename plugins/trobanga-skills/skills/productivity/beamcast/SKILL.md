---
name: beamcast
description: Write, validate and push Beamcast slide decks — `.bc` files in the Beamcast slide language — through the Beamcast JSON API. Use when the user wants to build or edit a talk deck on Beamcast, mentions a `.bc` file or the slide language, asks to push or pull a deck, or wants a picture uploaded into a deck.
---

# Beamcast decks

A Beamcast deck is one `.bc` file in the **slide language**: `@directive` lines and a closed set of text **marks**. The source is the deck, so uploading it and editing it are the same operation — replace the source.

The parser refuses a deck it does not understand and names the line. Never guess at markup: [`slide-language.md`](slide-language.md) holds every directive, mark and rejection rule.

## Setup

`scripts/bc.sh` talks to the API. It needs `curl` and `jq`.

- `BEAMCAST_TOKEN` holds the API token. Without it the script stops before any request.
- `BEAMCAST_HOST` overrides the host. It defaults to `https://beamcast.trobanga.de`.

If `BEAMCAST_TOKEN` is unset, stop and ask the user to export it. Do not read it out of a project file.

## The loop

Write the deck locally, prove it parses, then push it.

1. **Write** the `.bc` file. Consult [`slide-language.md`](slide-language.md) for every directive and mark you are not certain of.
2. **Check** it: `bc.sh check <file>`. This parses without saving and needs no presentation to exist, so it is the cheap gate. It prints `N slides` or names the failing line.
3. **Fix** every line the check names, then check again. The completion criterion is a clean parse, not a plausible-looking file.
4. **Push** it: `bc.sh push <slug> <file>`. The save applies to a running session at once.

A push of a deck the parser refuses changes nothing and reports the line, so a failed push is safe. Checking first is still cheaper than pushing to find out.

### Commands

| Command | What it does |
|---|---|
| `check <file>` | Parse a deck without saving it. |
| `list` | List your presentations: slug, title, last change. |
| `new <title> [file]` | Create a presentation, optionally with a deck. |
| `pull <slug> [file]` | Download the deck source. |
| `push <slug> <file>` | Upload the deck source. |
| `rename <slug> <title>` | Change the title. |
| `rm <slug>` | Delete a presentation. |
| `images` | List your stored pictures. |
| `image <file>` | Upload a picture and print its `/i/<id>` mark. |
| `rm-image <id>` | Delete a stored picture. |

Ask the user before `rm` or `rm-image`. Nothing sweeps and nothing restores.

## Pictures

To put a generated diagram in a deck:

1. Write the SVG or PNG to a file.
2. Run `bc.sh image <file>`. It prints one mark, such as `/i/Jz7qP0aXm2Kd8Rue`.
3. Paste that mark into the deck: `![a coverage curve](/i/Jz7qP0aXm2Kd8Rue)` inside an `@area`, or `@background /i/Jz7qP0aXm2Kd8Rue`.

Every upload mints a new id, so re-uploading a changed picture gives a new mark. Replace the old mark in the source, and delete the old picture if it is now unused.

## Traps

Each of these cost a previous session real time.

- **A deck the parser refuses never reaches the column.** `push` and `new` both parse first. A refusal is the whole story: read the line number it gives you.
- **`rename` changes the title and nothing else.** The endpoint reads the title alone and answers 200 to any other field, having ignored it. To change the deck, push the source.
- **`---` separates slides. `--` is a build mark.** They are different marks and one is not a typo of the other.
- **Every image upload mints a new id.** There is no update-in-place.
- **`/i/<id>` is a path into one Beamcast.** A deck carrying those marks draws nothing on a second instance.
- **Rewording a poll question resets its votes,** because the poll id derives from the question text.

## Testing the script

`tests/run-tests.sh` runs offline: it points `bc.sh` at a fake curl through `BEAMCAST_CURL` and checks the request that goes out. Run it after any change to `bc.sh`.
