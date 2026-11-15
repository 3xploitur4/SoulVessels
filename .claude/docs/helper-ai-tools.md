# Helper AI tools — save Claude usage by delegating

The user wants to stop hitting the 5-hour usage limit. You (the main session, Fable)
stay the **lead**: you plan, decide, write the tricky code and review. Hand routine,
well-specified work to the free helper CLIs below, then review their diff. Every
token a helper spends is one you don't.

All helpers are **free tiers only**. Never sign up for, upgrade to, or suggest a paid
plan or API key. If a helper says it is out of quota, switch to another helper or do
the task yourself — don't ask the user to pay.

## The helpers

Run them through the wrapper (it adds the project rules from `AGENTS.md` and logs
to `production/ai-helpers/logs/`):

    bash tools/ai-helpers/delegate.sh <tool> "<task>" [model]

First run in a session: `bash tools/ai-helpers/delegate.sh check` — it lists which
helpers are reachable. The wrapper adds `%APPDATA%\npm` and `%LOCALAPPDATA%\agy\bin`
to PATH itself, so helpers installed after Claude Code started are still found.

| Tool | Best for | Free limit | Notes |
|---|---|---|---|
| `opencode` | Default workhorse: boilerplate, new small scripts, unit tests, data files | IP-rate-limited free models | Pass a free model as arg 3, e.g. `opencode/<name>-free`. List them with `opencode models opencode` and pick ones ending in `-free` (often Qwen / Kimi / GLM / DeepSeek / MiniMax variants — the list changes) |
| `agy` (Antigravity, Gemini) | Reading lots of code at once: "find every place that…", summaries of a folder, big refactor plans | Weekly quota | Huge context; good for research so *you* don't read 30 files |
| `codex` | Focused bug fixes, single-system implementations, test fixes | Small (free ChatGPT) | Save for tasks that need a stronger coder |
| `copilot` | Quick small edits, shell/git questions | Few monthly credits | Use last |

If a command's flags have changed, run `<tool> --help` once and fix
`tools/ai-helpers/delegate.sh`.

## Claude subagents too

For work that needs Claude-level judgment but not Fable, spawn a subagent with a
cheaper model (`model: sonnet`, or `haiku` for lookups/formatting). The agents in
`.claude/agents/` already carry tiers — see `.claude/docs/model-tiers.md`.

Order of preference for a task: **free helper CLI → haiku/sonnet subagent → you.**

## What to delegate / keep

Delegate: new scripts from a clear spec, unit tests, data/balance files,
repetitive changes across files, doc comments, renames, searches and summaries,
first drafts of UI scenes, fixing failing tests with a known cause.

Keep: architecture and design decisions, anything touching save data or
`project.godot`, cross-system changes, final review, commits, anything the user
must approve under the Collaboration Protocol.

## How to write a delegated task

A helper starts with zero context, so the task text must stand alone:

- the goal in one sentence
- exact file paths to create/edit, and files to read for reference
- the interface: function names, signals, types, where data comes from
- acceptance: which test to add/run and what must pass
- "do not touch anything else"

Example:

    bash tools/ai-helpers/delegate.sh opencode "Create src/world/bounce_mushroom.gd: an Area3D that launches the player upward. Read src/player/player.gd for the velocity API and data/ for how tuning values are loaded; put launch_speed in data, not code. Add tests/unit/world/test_bounce_mushroom.gd and run bash tests/run_tests.sh. Touch only those two files plus the data entry." opencode/<free-model>

## After every delegated task — review loop

1. `git diff --stat` then `git diff` — check it touched only what you asked.
2. Run `bash tests/run_tests.sh` (and the smoke test if gameplay changed).
3. Good → keep it. Small issues → fix yourself or send a follow-up task with the
   exact problem. Bad → `git restore <files>` and try another helper or do it yourself.
4. Note in `production/session-state/active.md` what was delegated and to which tool.

Run independent tasks on different helpers in parallel when they touch different files.
