"""Mechanical checks of one skill folder, from CHECKLIST.md.

    python3 check_skill.py <skill-dir>

Prints one PASS or FAIL line per check and exits 1 if any check fails,
2 on a wrong number of arguments.
The checks that need judgement stay in CHECKLIST.md.
"""

import os
import re
import sys
from collections import namedtuple

Result = namedtuple("Result", "check ok detail")

# the limits of the Agent Skills spec, as Anthropic's best-practices page
# states them
NAME_PATTERN = re.compile(r"^[a-z0-9-]{1,64}$")
RESERVED_WORDS = ("anthropic", "claude")
DESCRIPTION_MAX = 1024
# Anthropic and Claude Code both give 500 lines as the outer bound of a
# SKILL.md body
BODY_MAX_LINES = 500
# Anthropic: a reference file over 100 lines needs a table of contents,
# because the agent may preview it with a partial read
CONTENTS_FROM_LINES = 100


def split(text):
    """The frontmatter lines of `text` and its body, without the `---` lines."""
    lines = text.split("\n")
    if lines[0].strip() == "---":
        for i, line in enumerate(lines[1:], start=1):
            if line.strip() == "---":
                return lines[1:i], "\n".join(lines[i + 1:])
    return [], text


def frontmatter(text):
    """The `key: value` pairs of the frontmatter of `text`."""
    fields = {}
    key = None
    for line in split(text)[0]:
        if line.startswith((" ", "\t")):
            # a continuation line of a block (`>` or `|`) or plain multi-line value
            if key is not None:
                fields[key] = (fields[key] + " " + line.strip()).strip()
            continue
        name, sep, value = line.partition(":")
        if not sep:
            continue
        key = name.strip()
        value = value.strip()
        if re.fullmatch(r"[>|][+-]?", value):
            value = ""
        fields[key] = value.strip("\"'")
    return fields


def check_name(fields):
    name = fields.get("name", "")
    if not NAME_PATTERN.match(name):
        return Result("name", False,
                      f"{name!r} is not 1-64 lowercase letters, digits, hyphens")
    reserved = [w for w in RESERVED_WORDS if w in name]
    if reserved:
        return Result("name", False, f"{name!r} contains {reserved[0]!r}")
    return Result("name", True, "")


def check_description(fields):
    description = fields.get("description", "")
    if not description:
        return Result("description", False, "missing or empty")
    if len(description) > DESCRIPTION_MAX:
        return Result("description", False,
                      f"{len(description)} characters, over {DESCRIPTION_MAX}")
    if re.search(r"<[A-Za-z/][^>]*>", description):
        return Result("description", False, "contains an XML tag")
    return Result("description", True, "")


def check_length(text):
    lines = len(split(text)[1].strip().split("\n"))
    if lines >= BODY_MAX_LINES:
        return Result("length", False,
                      f"body has {lines} lines, {BODY_MAX_LINES} or more")
    return Result("length", True, "")


def points_into(base, path):
    """Whether `path`, written in backticks, names a file of the skill: its
    first part exists in the folder `base`. Any other path names a file of the
    user's project, such as `docs/adr/`; so does one that starts with `/`, `./`
    or a hidden folder, which holds tool state."""
    first = path.split("/", 1)[0]
    return (re.fullmatch(r"[\w./-]+", path) is not None and first != ""
            and (first == ".." or not first.startswith("."))
            and os.path.exists(os.path.join(base, first)))


def local_links(text, base):
    """Targets of the pointers in `text` that point into the skill: Markdown
    links, paths in backticks that `points_into` the folder `base`, and
    `${CLAUDE_SKILL_DIR}/` paths, which only resolve in the skill and so are
    pointers wherever they stand.

    Other links inside code are examples, not pointers, so they are skipped."""
    targets = re.findall(r"\$\{CLAUDE_SKILL_DIR\}/([\w./-]+)", text)
    text = re.sub(r"^(```|~~~).*?^\1", "", text, flags=re.M | re.S)
    targets += [path for path in re.findall(r"`([^`\n]*)`", text)
                if points_into(base, path)]
    text = re.sub(r"`[^`\n]*`", "", text)
    for target in re.findall(r"\[[^\]]*\]\(([^)\s]+)[^)]*\)", text):
        if re.match(r"[a-z][a-z0-9+.-]*:", target) or target.startswith("#"):
            continue
        targets.append(target.split("#", 1)[0])
    return targets


def check_links(skill_dir, text):
    missing = [t for t in local_links(text, skill_dir)
               if not os.path.exists(os.path.join(skill_dir, t))]
    if missing:
        return Result("links", False, "missing: " + ", ".join(missing))
    return Result("links", True, "")


def is_reference(path):
    """A Markdown file other than a SKILL.md: a link to any SKILL.md hands
    over to that skill instead of disclosing reference."""
    return path.endswith(".md") and os.path.basename(path) != "SKILL.md"


def disclosed(skill_dir, text):
    """The reference files that `text` links and that exist."""
    files = []
    for target in local_links(text, skill_dir):
        path = os.path.normpath(target)
        if (is_reference(path) and path not in files
                and os.path.isfile(os.path.join(skill_dir, path))):
            files.append(path)
    return files


def read(skill_dir, path):
    with open(os.path.join(skill_dir, path)) as f:
        return f.read()


def check_contents(skill_dir, files):
    """A file over CONTENTS_FROM_LINES opens with a table of contents: its
    first `##` heading is one."""
    missing = []
    for path in files:
        text = read(skill_dir, path)
        if len(text.rstrip("\n").split("\n")) <= CONTENTS_FROM_LINES:
            continue
        first = re.search(r"^## (.*)$", text, flags=re.M)
        if not first or "contents" not in first.group(1).lower():
            missing.append(path)
    if missing:
        return Result("contents", False,
                      "no table of contents first: " + ", ".join(missing))
    return Result("contents", True, "")


def check_depth(skill_dir, files):
    """Every Markdown file a disclosed file links is also linked from
    SKILL.md, because the agent may only skim a file it reaches second-hand."""
    deeper = []
    for path in files:
        folder = os.path.join(skill_dir, os.path.dirname(path))
        for target in local_links(read(skill_dir, path), folder):
            linked = os.path.normpath(
                os.path.join(os.path.dirname(path), target))
            if (is_reference(linked) and linked not in files
                    and linked not in deeper):
                deeper.append(linked)
    if deeper:
        return Result("depth", False,
                      "not linked from SKILL.md: " + ", ".join(deeper))
    return Result("depth", True, "")


def check_slashes(skill_dir, text):
    backslashed = [t for t in local_links(text, skill_dir) if "\\" in t]
    if backslashed:
        return Result("slashes", False,
                      "use forward slashes: " + ", ".join(backslashed))
    return Result("slashes", True, "")


def check(skill_dir):
    """Run every check on the skill in `skill_dir`; return a list of Result."""
    if not os.path.isfile(os.path.join(skill_dir, "SKILL.md")):
        return [Result("skill", False,
                       f"no SKILL.md in {skill_dir}; pass the skill's folder")]
    text = read(skill_dir, "SKILL.md")
    fields = frontmatter(text)
    files = disclosed(skill_dir, text)
    return [check_name(fields), check_description(fields), check_length(text),
            check_links(skill_dir, text), check_contents(skill_dir, files),
            check_depth(skill_dir, files), check_slashes(skill_dir, text)]


def main(argv):
    if len(argv) != 1:
        print("usage: python3 check_skill.py <skill-dir>", file=sys.stderr)
        return 2
    results = check(argv[0])
    for r in results:
        print(("PASS " if r.ok else "FAIL ") + r.check
              + ("" if r.ok else ": " + r.detail))
    return 0 if all(r.ok for r in results) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
