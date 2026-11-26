# puzzle-runs

Opt-in run logging for Puzzle in Claude Code.

The `log-runs` skill teaches an agent how to record its work on a mapped process as runs. A skill only loads when the agent thinks to reach for it. This plugin removes that step: with it on, every session starts with the instruction to log, and the agent is reminded once if it is about to finish with a run still open.

## What it does

| When | What happens |
|---|---|
| A session starts (or resumes, clears or compacts) | The agent is told to load `puzzle-skills:log-runs` before doing work the workspace maps, log one event per meaningful action, and close every run as success or failed. |
| The agent calls `log_run_event` | The plugin notes which runs are open and which were closed. It reads the call the agent already made. It sends nothing. |
| The agent is about to finish | If a run it opened has no final status, the agent gets one reminder naming the run. It closes the run, or says in one line why it stays open, and then finishes. It is never reminded twice about the same run. |

It is a reminder, not a gate. The agent can always finish.

## Install

You need a Puzzle connection in Claude Code, on a workspace that has Runs. If you have neither yet, install `puzzle@puzzle-skills` first.

```bash
claude plugin marketplace add puzzle-app/puzzle-skills
```

```bash
claude plugin install puzzle-runs@puzzle-skills --scope user
```

This also installs `puzzle-skills`, which holds the `log-runs` skill. Start a new session for it to take effect.

To turn it on for one project only, use `--scope project` from that project's folder.

## How the agent finds the step

Two ways, and both work together.

**It matches the work itself.** With no setup, the agent reads the map each time and logs on the step that matches what it did. If no step matches, it does the work, logs nothing, and tells you the map has a gap.

**You pin a section.** When a project's work always belongs to one process, add `.claude/puzzle-runs.json` to the project. The agent then goes straight to that section's steps.

```json
{
  "workspace": "Acme",
  "section": "Renewals",
  "section_id": 1234,
  "ref_type": "deal",
  "tool": "HubSpot",
  "agent_person_id": 812,
  "notes": "One run per deal. Skip deals under review."
}
```

Every field is optional.

| Field | Meaning |
|---|---|
| `workspace` | The workspace this project logs to. If the agent is connected to a different one, it tells you and does not log to the wrong map. |
| `section`, `section_id` | The process the work belongs to, by name, id or both. |
| `ref_type`, `tool` | The first two parts of the reference key, `type:tool:id`, so every run in the project is keyed the same way. |
| `agent_person_id` | The agent's own card on the People canvas, so the canvas shows who did the work. |
| `notes` | One line of anything else the agent should know about logging here. |
| `enabled` | Set to `false` to switch the plugin off for this project. |

The file holds settings only. Never put a token or a webhook URL in it.

## What it does not do

- It does not log anything itself. The agent makes every `log_run_event` call, through your Puzzle connection, following `log-runs`.
- It does not approve work. Events record what happened.
- It does not send data anywhere. The only thing it stores is a small file on your machine listing the runs the current session has open, removed after 14 days.
- It does not block the agent from finishing.

## Requirements

- Claude Code with plugin dependencies.
- `python3` on the path (macOS and most Linux systems have it). Without it the hooks do nothing and the session carries on.
- Runs on the workspace. Without it the agent says so once and carries on with the work.

## Turn it off

```bash
claude plugin uninstall puzzle-runs@puzzle-skills
```
