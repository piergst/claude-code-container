# Documentation contract

This repository belongs to an account enumerated by an external documentation site (the `accounts`
of the `projects.yml` in the doc-site repository). For a repository of that account, the site renders
the repository page from `README.md` and the status page from `STATUS.md`, both at the repository
root, and reads nothing else. A repository carrying neither of them gets no page: it is listed,
flagged, on the site's repository list.

## Language

`README.md` and `STATUS.md` are written in French. This contract stays in English.

## `README.md`

What the project is and how it is used. It is the repository page, so it carries the whole content
of that page. Only its `h2` and `h3` headings become the page table of contents; deeper headings are
not listed. Keep it minimalist and action-oriented: short recipes (install, run, configure),
concrete commands, no prose, no filler.

`README.md` may open with YAML front matter carrying a one-line `description` of the project. The
repos list shows it as the card text; without it, the site falls back to the opening sentence. Set it
when the opening sentence is not a good summary:

```yaml
---
description: Génère un PDF depuis un fichier Markdown.
---
```

A change that affects how the project is used belongs in `README.md`. Ask the user before rewriting
the file: extending it is expected, restructuring it is their call.

## `STATUS.md`

Where the work stands. It must open with YAML front matter:

```yaml
---
state: active
next: run the migration dry run on staging
---
```

`state` is one of `active`, `blocked`, `paused`, `done`, `dropped`. Any other value is reported as
an error on the site. `next` is a single line. Everything after the front matter is rendered as the
page body, so keep it short: a few bullets on what is done and what remains.

The site marks an entry as stale when `state` is `active` and the last commit touching `STATUS.md`
is more than 30 days old. Refresh the file, or move the state along, when the situation changes.

## How the site reads the files

- It fetches the default branch. Nothing appears on the page until the work is pushed.
- Relative links and images in either file are rewritten to point at the same commit on GitHub, so
  a relative path is resolved from the repository root.
