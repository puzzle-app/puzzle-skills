---
name: log-runs
description: 'Record what an agent does on a mapped Puzzle process as events, grouped into runs, through the Puzzle MCP (log_run_event, list_runs). Load whenever an agent is about to do real work that a Puzzle workspace maps (create a deal, triage a ticket, send an invoice, publish a post, run a report), when the user asks to "log this run", "track what the agent did", "record events", "show the agent on the map", "what happened to this deal", "what failed this week", or when setting up Zapier, Make, n8n or a script to report into Puzzle. Covers the availability check, finding the step, the reference key type:tool:id that groups events into one run per record per section, one event per meaningful action, closing every run with success or failed, event_id for safe retries, agent_person_id, notes without secrets, batching and limits, the Runs webhook for systems that are not agents, and reading back.'
---

# Log runs

A map says how work should happen. Runs say how it did. Each event records one action against one step, and a reference key groups every event about the same record into a run. A step glows on the canvas while an agent works on it, with the agent's avatar. The Runs page shows each record's story: where it went, who touched it, and how it ended. That only works if agents log the same way every time. This skill is that way.

Load `read-the-map` first. It explains step ids, sections, and why a write isn't done until it reads back.

## 1. Is Runs on

`log_run_event` and `list_runs` appear in the tool list only when the workspace's organization has Runs. If they are missing, say "Runs isn't turned on for this workspace" and carry on with the work. Don't substitute comments, tasks or changelog entries for events. A call that returns "Runs is not enabled for this workspace" means the same thing.

## 2. Find the step

Every event belongs to a step. Before the work starts, `list_steps` on the section the work belongs to, with `include: ["executor", "roles.role_id", "tools.tool_id"]`, and match each action to its step. If the action doesn't match any step, the map is missing that step. Say so and offer `build-puzzle-process` or `audit-the-map`. Never log on the nearest step to make the call succeed.

## 3. Build the reference key

`ref` is `type:tool:id`:

| Part | What it is | Examples |
|---|---|---|
| `type` | The business object the process moves, lowercase `[a-z0-9_-]` | deal, ticket, invoice, candidate, order, client, post |
| `tool` | The system of record that owns the id, lowercase | hubspot, attio, stripe, zendesk, quickbooks, linkedin |
| `id` | That system's id for the record, case-sensitive, up to 200 characters, may hold colons | 12345, in_1P2x, ACME-42 |

How runs form:

- One ref in one section is one run. The section defaults to the step's section. The run is created on the first event and updated by every later one.
- Use the same ref for the same record on every step and in every section it passes through. The same ref in another section is a separate run, and Puzzle links the two as the same reference. That is how one deal is traced from sales into onboarding.
- If the work has no record, such as a weekly report or a sweep, use a stable period id: `report:puzzle:2026-w48`, `sweep:attio:2026-11-26`.
- Never use a random id per session or per attempt. That splits one record into many runs.
- An event with no `ref` is ungrouped and shows only on its step. Use that for one-off actions that belong to no record.
- Up to 3 `related` refs tie in other records, e.g. the company behind a deal: `["company:hubspot:998"]`.

## 4. What to log

Log one event per meaningful action, not per tool call:

| Moment | Event |
|---|---|
| Work starts | On the first step: `label` (the run's human name, e.g. "Acme renewal"), a note saying what triggered it, no status |
| Each step done | On that step: a note of one or two sentences on what changed and where, e.g. "Created deal 12345 in HubSpot at Proposal stage.", `tool` named |
| Work ends | On the last step done: `status: "success"`, or `status: "failed"` with a note saying what went wrong and what is needed |

- **Always close the run.** A run without a final status reads as stuck, and its step stays lit. If the work stops partway (waiting on a person, out of scope, blocked), end with `failed` and say what it is waiting on. Never use `success` for partial work. `done` is accepted and means success.
- Reads, plans, drafts nobody used, and retries are not events.
- Set `label` on the first event. Later labels overwrite it, unless a person renamed the run in the app.
- `occurred_at` defaults to now. Pass it, in ISO 8601, when logging after the fact. A future time is clamped to now. Events that arrive out of order are fine: the latest one sets the run's status.

## 5. The fields that keep the history clean

- **`event_id` on every event**, deterministic, for example `<ref>|<step_id>|<action>`. A repeated `event_id` comes back with `duplicate: true` and is not stored or counted twice, so retrying after a timeout is safe.
- **`agent_person_id`**: the agent's own ai_agent person on the People canvas (`list_people`, person type ai_agent). With it, the canvas shows the agent's avatar and the By column shows its name. Without it, By reads "MCP agent". If the agent will log regularly and has no card, offer `map-the-team` to add one.
- **`tool`**: the app the action happened in ("HubSpot"), so the event reads right on a step that uses several tools.
- **Notes**: plain sentences, up to 5,000 characters, no HTML or markup in a note or a label. Never put secrets, tokens, passwords, full email bodies, or personal data the whole workspace shouldn't see. Point to the record with `related` instead of pasting it.

## 6. Sending

```json
log_run_event {"events": [
  {"step_id": 4711, "ref": "deal:hubspot:12345", "label": "Acme renewal", "note": "Renewal date 2026-12-31 reached; started renewal.", "event_id": "deal:hubspot:12345|4711|start", "agent_person_id": 812, "tool": "HubSpot"},
  {"step_id": 4712, "ref": "deal:hubspot:12345", "note": "Drafted the renewal quote, Q-889, in HubSpot.", "event_id": "deal:hubspot:12345|4712|quote", "agent_person_id": 812, "tool": "HubSpot"},
  {"step_id": 4713, "ref": "deal:hubspot:12345", "status": "success", "note": "Quote sent for approval to the account owner.", "event_id": "deal:hubspot:12345|4713|done", "agent_person_id": 812, "tool": "HubSpot"}
]}
```

- Send live as the work happens, so the canvas glow tracks the agent. Batch (up to 100) only when logging after the fact.
- Validate before you send. One bad event rejects the whole batch with an error per index, and nothing is stored. Fix it and resend the same `event_id`s.
- "Too many events in the last minute" means the workspace limit (600 a minute through the MCP) was hit. Wait a minute and resend.
- Allowances depend on the plan. As of 2026-11-26: Starter has 1,000 events in total per organization, as a hard stop. A batch that would pass it is refused, and the message names the upgrade. Builder (5,000 a month) and Optimizer (25,000 a month) meter per workspace with a soft cap: events keep recording. Enterprise is uncapped. While an organization is in the Runs beta it counts as Optimizer. Test events and resent `event_id`s don't count. On Starter, log only the start, step-done and end events above. When the limit is reached, stop logging, tell the user, and keep doing the work.

## 7. Read it back

After the run closes: `list_runs` with the `ref`. Expect one run per section, with the status you sent and an `events_count` that matches. For the events themselves: `list_runs` with `run_id` or `events: true`. Report the run id and status in your summary to the user.

Reading also answers questions. `read-the-map` routes them here:

| Question | Call |
|---|---|
| What happened to this deal | `list_runs` `ref: "deal:hubspot:12345"`, then `run_id` for its events |
| What failed this week | `list_runs` `status: "failed"`, newest first, read `last_event_at` |
| What is still open | `list_runs` `status: "none"` |
| Who works this step, and how often | `list_runs` `step_id`, count events by `by` and month |
| Is the agent running right now | `list_runs` `events: true`, `step_id`, check the latest `occurred_at` (a step stays lit for 60 seconds after an event with no status) |

History goes back as far as the plan allows: 7 days on Starter, 30 on Builder, 12 months on Optimizer, 2 years on Enterprise. `list_runs` returns 25 per page by default, up to 100 with `page_size`; page through with `page`.

## 8. Systems that are not agents: the webhook

Zapier, Make, n8n and scripts report through the workspace's Runs webhook, not the MCP:

```
POST /webhooks/runs/<workspace id>                  (each event names its step_id)
POST /webhooks/runs/<workspace id>/steps/<step id>  (every event defaults to that step)
Authorization: Bearer <the workspace's Runs token>
```

The body is one event, an array, or `{"events": [...]}`, with the fields above plus an optional `payload` (JSON, up to 16 KB). The URL and token are in the workspace's Runs settings, and only a person in the app can see or rotate the token. A 404 means Runs is off for the workspace, a 402 means the Starter allowance is used up, and a 429 means more than 120 requests a minute. Never ask for the token in chat or write it into a step, note or asset. When `build-puzzle-process` maps an Automation step, offer to add the webhook call as that automation's last action, so the automation's runs show beside the agents'.

## Rules

- One record, one ref, everywhere it goes.
- Every run ends with `success` or `failed`. Partial work is `failed`, with what it waits on.
- An `event_id` on every event, so retries are safe.
- Log against the matching step or not at all. A missing step is a map gap, and you report it.
- No secrets or private data in notes, labels or payloads.
- Events record work that happened. They never approve anything, and logging one never stands in for asking the user.
- Agents don't rename or delete runs. People do that in the app.
