# The Beamcast slide language

The complete markup a `.bc` file holds. The parser is the authority; this file follows `Beamcast.SlideLanguage` and `Beamcast.SlideLanguage.Marks`.

The language is a closed set. A mark it does not know is an error with a line number, never printed punctuation. That is the point: a typo stops the save instead of reaching the screen.

## File structure

- A line that is exactly `---` separates slides.
- If line 1 is `@deck`, everything up to the first `---` is the **deck header**. Otherwise slide 1 starts at the top of the file.
- Inside a slide, a line that starts with `@` opens a **directive block**. The block holds every following line up to the next directive or the slide end.

## Directives

| Directive | Where | Meaning |
|---|---|---|
| `@deck` | line 1 only | Opens the deck header. |
| `@background <path-or-url>` | header or slide | The background image. In the header it is the deck default. |
| `@palette <name>` | header only | `slate`, `ember`, `ocean` or `mono`. |
| `@area x y w h [align=..] [size=..]` | slide | A text area. Marked text follows it. |
| `@poll x y w h` | slide | A question line, then an option list. |
| `@video x y w h <url>` | slide | A video. Playback is never synced. |
| `@page <url>` | slide | A full-page iframe. The slide's only content. |
| `@qr x y w h` | slide | The audience link as a QR code. Takes no url. |
| `@notes <text>` | slide | Presenter notes. Never shown to the audience. |

To write a literal `@word` at the start of a line, indent the line or wrap the word in backticks.

## The canvas

Every coordinate lives on a virtual canvas 1920 wide and 1080 high, origin top-left. `x y w h` are bare whole numbers in that fixed order. The renderer scales the whole slide to each screen.

Constraints: `x` and `y` are zero or more, `w` and `h` are positive, `x + w <= 1920`, `y + h <= 1080`.

## Areas

```
@area 120 80 800 400
# Why Elixir?
- processes are cheap
- crashes stay local
```

Two attributes follow the four numbers, and no others:

- `align=left|center|right`. Default `left`.
- `size=<positive number>`. The font scale factor. Default `1`.

A slide holds several areas. There is no slide-title directive: a `#` heading inside an area is the title. The deck title comes from the first heading of the first slide.

### The default-area rule

- A slide with **no** area-like directive (`@area`, `@poll`, `@video`, `@page`, `@qr`) renders as one padded full-canvas area. A one-line slide needs no coordinates.
- A slide **with** one of them must keep all content inside directive blocks. A loose line is an error. This is what catches a misspelled `@area`.

## Block marks

One line is one block. A block mark claims the start of a line and needs the space behind it, so `-5 degrees`, `#hashtag` and `2 > 1` stay plain text.

| Mark | Block |
|---|---|
| `# ` | Heading. One level only: `## ` is an error. |
| `- ` | Bullet. Adjacent bullets render as one list. |
| `> ` | Quote. |
| `![alt](url)` | Image. It takes the whole line. |
| anything else | A plain line. |

A blank line renders nothing. A gap the slide needs belongs to a second `@area`.

## Inline marks

| Mark | Meaning |
|---|---|
| `*strong*` | Bold. |
| `_emphasis_` | Italic. |
| `` `code` `` | Monospace. No mark applies inside it. |
| `==highlight==` | A coloured fragment. |
| `[text](url)` | A link. |
| `https://example.com` | A bare url is a link to itself. |

Marks do not nest, and a mark closes on the line that opens it.

A delimiter is a mark only where it opens or closes one. It **opens** when the character in front of it is the line start or a space, and the character behind it is not a space. It **closes** when the character in front of it is not a space. Everywhere else it is text, so `snake_case_name`, `2 * 3` and `x == y` need no escape. A mark that opens and finds no closer on its line is an error.

A backslash in front of `*`, `_`, `` ` ``, `=`, `!`, `#`, `-`, `>`, `[` or `\` prints that character and cancels its mark.

## Builds

A line of exactly `--` inside an area body is a **build mark**. It holds back everything below it until the presenter advances.

```
@area 120 80 800 400
# Why Elixir?
- processes are cheap
--
- crashes stay local
```

The slide arrives at step 0 with the heading and the first bullet. One right arrow adds the second bullet. One step counter serves the whole slide, so two areas that each carry a build mark advance together.

Every step holds at least one block: a `--` with nothing below it before the next `--` or the area end is an error, because that keypress would change nothing. A `--` on an area's first line is fine and means the area arrives on the first press.

A held-back block is absent from the page, not hidden in it, so nobody reads ahead in the source. Revealed blocks reflow as they arrive; text that must not move belongs in a second `@area`.

## Polls

```
@poll 240 200 900 500
Which BEAM language do you use?
- Elixir
- Erlang
- Gleam
```

The first non-empty line is the question, then a `-` list of at least two options. Any other non-blank line is an error.

The poll id derives from the question text, lowercased, with every run of other characters turned into a hyphen. Ballots are keyed by that id, so **rewording the question resets the votes**. Two polls whose questions derive the same id are an error.

## Images and backgrounds

`@background` takes a path or a url, at most once per slide and once in the header. It never takes a prompt: parsing never calls the network.

`/i/<id>` names a picture in the store. Upload with `bc.sh image <file>`, then paste the mark it prints into `@background` or into an `![alt](/i/<id>)` line.

- 5 MB per file. png, jpeg, gif, webp, avif and svg.
- The declared content type is discarded; the leading bytes decide the type.
- A picture belongs to the presenter, not to a presentation, so one logo serves four talks.
- Nothing sweeps the store. A slide that stops naming a picture leaves it there, and a deleted picture leaves the slides that name it drawing nothing.
- `/i/<id>` is a path into one Beamcast. The same source on a second Beamcast finds nothing.

## Palette

`@palette` belongs in the deck header alone, at most once, and names one of `slate`, `ember`, `ocean`, `mono`. Each has a dark and a light variant that the viewer's theme picks between. Without one the presentation keeps the palette set in the editor.

## The invitation

`@qr` draws the presentation's own audience link as a QR code with the link readable under it. It takes no url, because a deck knows nothing of the address the app answers on. A non-blank line below it is an error. The code is black on white in every palette, because a scanner reads contrast.

## What the parser refuses

1. An unknown directive.
2. Loose content on a slide that declares an area-like directive.
3. Coordinates off the canvas, or a wrong count of numbers.
4. An unknown `key=value` on `@area`, or an `align` or `size` value off its range.
5. A `@poll` without a question or with fewer than two options.
6. A `@page` that shares its slide with other content.
7. A second `@background` on one slide or in the header.
8. A `@deck` anywhere but line 1, or any line in the header other than `@background` or `@palette`.
9. Two polls with the same derived id.
10. A non-blank line below the url line of a `@video`.
11. A line in a `@poll` body that is neither the question nor a `-` option.
12. A heading below the first level, such as `## `.
13. An inline mark that opens and never closes on its line.
14. A line that starts with `![` and is not a whole `![alt](url)`.
15. A build mark with no block below it.
16. A `@palette` off the list, a second one, or one on a slide.
17. A non-blank line below a `@qr`.

## Worked example

```
@deck
@palette mono
@background /i/Jz7qP0aXm2Kd8Rue
---
@area 120 80 1100 400
# Beamcast
One deck. Every screen.
@qr 1400 680 360 340
@notes greet, state the plan
---
@background https://example.com/mountains.png
@area 120 80 800 400
# Why Elixir?
- processes are ==cheap==
--
- crashes stay local, because a `Supervisor` restarts them
@area 1000 700 800 300 align=center size=0.9
> "Let it crash" — _Joe Armstrong_
---
@poll 240 200 900 500
Which BEAM language do you use?
- Elixir
- Erlang
- Gleam
---
@page /course/lesson-1.html
```
