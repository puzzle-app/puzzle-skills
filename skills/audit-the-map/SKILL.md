---
name: audit-the-map
description: Audit a Puzzle workspace for gaps between the map and a complete, current picture of the operation, then propose fixes. Load when the user asks "what's missing", "is this map complete", "audit the workspace", "what's stale", "find the gaps", "health check", or before a review, a handoff, a costing, or an automation roadmap that depends on the map being right. Finds steps without an executor, role, tool, attributes, cost inputs or notes; roles without rates or people; conditionals with unlabeled or dangling branches; go-to and subflow steps pointing nowhere; unused tools and data; Live work with no changelog entry behind it; outstanding tasks; and shared views exposing draft work. Reads only, then writes fixes one approved batch at a time.
---

# Audit the map

A map is useful in proportion to how complete and how current it is. This skill reads a workspace, or one tab or section of it, scores every gap that would make the picture wrong or unusable, and hands the user a ranked fix list. Nothing is written until the user approves a batch.

Load `read-the-map` first. It carries the calls, the include fields and the two tool ids.

## Scope first

If a "Workspace rounded out" changelog entry exists (`list_changelog_entries`, `query: "rounded out"`), read it first: its unticked stages are the first findings, and the round-out pass in `start-here` is the fix for them.


Ask once, if the request doesn't say:

- **How much of the workspace**: the whole thing, one Workflow tab, or one section. Default to one tab; a whole workspace audit on a big map is a long read.
- **Which state**: the current state only (Live steps), or everything including Draft, Testing and In_Progress. Default to everything except Archived.
- **What it's for**: a general health check, a costing (then cost inputs weigh most), an automation roadmap (then executor and tool gaps weigh most), a handoff or shared view (then notes and roles weigh most). The purpose sets the ranking.

## Read

Pull everything the checks need, in as few calls as the scope allows:

1. `list_tabs` for every canvas.
2. `list_sections` per Workflow tab with `include: ["step_count", "description", "notes"]`.
3. `list_steps` per section with `include: ["type", "status", "executor", "notes", "duration", "frequency", "target", "roles.role_id", "roles.role_name", "roles.involvement", "tools.tool_id", "tools.tool_name", "connections.connection_id", "connections.to_step_id", "connections.from_step_id", "connections.label"]`. Page through; `meta.total` is the count.
4. `list_attributes` with `step_id` only for steps that have a tool and might touch data (form, database, email, document, payment, task steps with a tool). Or pull every attribute once with `include: ["steps.step_id", "steps.kind", "entity_name", "tool_name"]` and index by step.
5. `list_roles` with `include: ["hourly_rate", "status", "type", "team_name", "step_count", "people.person_id"]`.
6. `list_people` with `include: ["role_count", "person_type", "active", "end_date"]`.
7. `list_tools` scope `workspace` with `include: ["status", "cost_items", "tool_group_name"]`, then `list_steps` with `tool_id` per tool to count usage (or use the step list already loaded).
8. `list_entities` with `include: ["attribute_count", "step_count", "tool_name"]`.
9. `list_assets` with `include: ["status", "step_count", "tool_name"]`.
10. `list_tasks` with `completed: false` and `include: ["step_name", "section_name"]`.
11. `list_changelog_entries` with `include: ["status", "associated_steps.step_id", "associated_tools.account_tool_id"]`; on the Optimizer plan add `"current_state", "future_state", "cost_analysis"`.
12. `list_shared_views` with `include: ["items.type", "items.id", "items.name"]`.
13. `list_tags` with `include: ["tag_group_name", "step_count"]`, when the workspace has tag groups.
14. `list_comments` with `resolved: false`, `top_level: true` and `include: ["author", "created_at", "step_name", "section_name", "replies"]`.
15. Charges, when the workspace logs them: `list_tool_charges` per Active tool with cost items, for `meta.spent_last_12_months` and the latest `charged_on`.
16. Runs, when `list_runs` is in the tool list: `list_runs` with `status: "failed"` and with `status: "none"`, and `list_runs` with `events: true` for the steps in scope, over the history the plan allows.

Save the raw results if the workspace is large; the checks run over the whole set.

## The checks

Each check names what it finds, why it matters, and the fix. Severity: **blocks** (the map gives a wrong answer), **weakens** (an answer is incomplete), **tidies** (cosmetic or housekeeping).

### Steps

| Check | Severity | Why | Fix |
|---|---|---|---|
| No executor | blocks | Costing, automation planning and "who does this" all depend on it | Set executor per the note or ask |
| Person step with no responsible role | blocks | Nobody owns it; cost is zero | Link a role (`link_to_steps`, type role, involvement responsible) |
| Person step missing duration or frequency | blocks for costing | Labor cost cannot be computed | Set both on the step (`update_workflow`) after the user confirms estimates |
| Step with a tool but no attributes, on a type that handles data (form, database, document, email, payment) | weakens | The data model does not show what this step reads or writes | Propose attributes; link with kind trigger/input/output |
| Step with no tool, executor Automation or AI Agent | blocks | Software with no system named | Ask which tool; link it |
| Empty notes | weakens | The map can't be run from the map | Draft a Purpose/Inputs/Procedure/Output note from the title and context, marked proposed |
| Type left as task where the name says email, form, meeting, payment, delay | tidies | The canvas vocabulary is wrong | Set the type |
| Title not verb-first or over ten words | tidies | Scan-ability | Propose a retitle |
| Status Draft or Testing inside a section where every other step is Live | weakens | Either the step is stale or the section isn't fully live | Ask which |

### Flow

| Check | Severity | Why | Fix |
|---|---|---|---|
| Conditional with fewer than two outgoing connections | blocks | A fork with one outcome is not a fork | Add the missing branch or change the type |
| Outgoing connection from a conditional with no label | weakens | The branch cannot be read without opening steps | Label it ("✅Yes", "❌No", the condition) |
| Step with no connections in a section that has connections | weakens | Orphan: either unplaced or a leftover | Connect it or archive it |
| `go_to` or `subflow` with no target, or a subflow pointing at an archived section | blocks | The jump goes nowhere | Set `target_step_id` or `target_section_id`; when the section it ran is gone and no replacement exists yet, clear it with `target_section_id: null` and say so |
| Section with no trigger step (every step has an incoming connection) | weakens | A loop with no entry | Identify the trigger |
| Section with more than one step that has no incoming connection, not by design | tidies | Multiple entry points or fragments | Confirm which are triggers |
| Section with zero steps | tidies | Empty container | Delete or fill |
| Two sections with the same name on one tab | tidies | Fragmented process | Merge, or rename with the distinction |

### Team and people

| Check | Severity | Why | Fix |
|---|---|---|---|
| Role with no hourly rate | blocks for costing | Every step it owns costs zero | Research a rate, confirm, set it (`update_org`) |
| Role that owns steps but has no person | weakens | Nobody is in the seat on the map | Add or assign a person (`update_people`, add_role_ids), or note it as vacant |
| Role that owns Live steps and is `planned`, `hiring` or `archived` | weakens | Live work the map says nobody holds, or a retired seat still doing it | Assign a person and set `filled`, or move the steps to the role that does them (`update_org`, `link_to_steps`) |
| Role `filled` with nobody in it, or `planned` or `hiring` with someone in it | tidies | Status and seat disagree | Set the status to match (`update_org`); ask if the person is leaving |
| Role still `draft` and owning steps | tidies | Never reviewed; older roles were backfilled to `draft` when empty | Propose `planned`, `hiring` or `archived` for the user to confirm |
| Inactive person (`active: false`, or an `end_date` in the past) still holding a role | weakens | The map names someone who has left as doing the work | `update_people` remove_role_ids; set the role to `hiring` or `planned`; never delete the person |
| Person with no role | tidies | A name with no position | Assign a role or mark as a vendor/advisor |
| Role with zero steps | tidies | Either unmapped work or a leftover | Ask |

### Tools and data

| Check | Severity | Why | Fix |
|---|---|---|---|
| Workspace tool linked to zero steps | weakens | Paying for something the map says nobody uses, or unmapped work | Ask; link or mark Cancelled |
| Tool with status Active and no cost items | weakens for costing | Tool cost is unknown | Ask for the cost; set `cost_items` |
| Entity with no attributes | tidies | A record with no fields | Propose attributes or delete |
| Attribute linked to no steps | tidies | A field nothing touches | Link it or leave it, noted |
| Active tool with cost items and no charge in 90 days, in a workspace that logs charges | weakens | Either billing stopped and the plan is stale, or charges aren't being logged | Ask; log the missing charges or fix the status and cost items |
| Actual 12-month spend more than about 10% above the cost items annualized | weakens for costing | Every cost figure built on the plan is low | Show plan and actual; the user decides which to correct |
| Tool with charges and no cost items | weakens for costing | Real spend the cost model can't allocate | Propose cost items from the charges, marked proposed |
| Charge with no reference, or two charges sharing one | tidies | Can't trace it to an invoice, or it may be counted twice | Ask for the invoice; on a confirmed duplicate, remove it on the user's word |
| Asset Deprecated but still linked to Live steps | weakens | The step points at a dead template | Replace or unlink |

### Runs (when the workspace has Runs)

| Check | Severity | Why | Fix |
|---|---|---|---|
| Step with events but no executor | blocks | Work is happening there and the map can't say who or what does it | Set the executor from the events' By (agent, person, system) |
| Step whose events come from an agent or system but whose executor is Person (or the reverse) | weakens | The map and the record disagree on who does the work | Ask; fix the executor or the logging |
| Run with no status and no event in more than a day | weakens | It reads as stuck, or the agent never closed it | Ask the owner whether it is waiting or abandoned; the agent closes it with `failed` and a note, or a person resolves it in the app |
| Failed run with no note | weakens | The failure can't be acted on | Ask whoever ran it; agents that log follow `log-runs` |
| Step with a high failure share (about one run in five or more over the period) | weakens | The step breaks often | List it for `find-automation-opportunities` and the process owner |
| Live step in a section with runs that never receives events | tidies | Skipped in practice, or simply not logged | Ask which |

### Decisions and housekeeping

| Check | Severity | Why | Fix |
|---|---|---|---|
| Live section with no changelog entry touching any of its steps | weakens | No recorded reason for how it works | Propose an entry (`log-a-decision`) capturing what is known, marked retroactive |
| Changelog entry in_progress or planned with every linked step Live | tidies | Status lags the map | Update the entry status |
| Outstanding tasks on Live steps | weakens | Work the map says is unfinished | List them for the owner |
| Shared view containing a section with Draft or Testing steps | weakens | The public sees unfinished work | Remove the section from the view or finish the work |
| Tag on no step, or a tag group with no tags | tidies | Clutter in every tag picker | Ask whether it is still meant to be used; retiring it is the user's call, in the app |
| Two tags that differ only in wording ("Weekly", "Weekly cadence") | tidies | One filter split in two | Propose one name and re-tag the other's steps (`link_to_steps` type tag, `unlink_from_steps` type step_tag) |
| Tag that repeats a field: a role, team or person; a tool; manual or automated (flags such as Approval required, Needs review or Deprecated are not this) | tidies | Two answers to one question, and the tag drifts from the field | Propose the field instead (role, tool, executor); retiring the tag is the user's call, in the app |
| Cadence tag that disagrees with the step's frequency (Weekly on a step that runs 20 times a month) | weakens | The schedule and the cost tell different stories | Ask which is right; fix the frequency or the tag |
| Open question comment older than 30 days | weakens | Something unconfirmed is being treated as known | List it for the owner of the step, with who asked |
| Open pain_point comment with no reply, or on a step that is now Archived | weakens | A reported problem with no answer, or answered by a change nobody closed out | Ask the process owner (on a client engagement, the client) for the proposed solution in the thread, or reply with what already addresses it; the team that builds the change resolves it once that is Live, or at once if the step it named is gone |
| Changelog entry that changes cost (a redesign, an automation, a tool swap) with no current state or no future state set | weakens | The change has no cost case anyone can check | Set both sides through `log-a-decision` |
| Changelog entry whose cost analysis shows a side at zero while it holds steps | weakens | The figure looks like a saving or a cost that isn't real | List the steps missing duration, frequency or a rated role on that side; fix the inputs, never the figure |

## Score and rank

Count findings per check and per section. Rank the fix list by severity, then by how many answers the gap breaks (a role without a rate that owns twenty steps outranks one that owns two), then by effort (one `update_workflow` call outranks a research task). Weight by the stated purpose.

Report the map's shape at the top so the numbers mean something: tabs, sections, steps, by executor, by status.

## Report format

```
# Audit: <workspace or tab or section>, <date>
Scope: <n> sections, <n> steps (<n> Person / <n> Automation / <n> AI Agent; <n> Live / <n> Draft / <n> Testing). Purpose: <health check | costing | automation | handoff>.

## Blocks (<n>)
1. <n> Person steps have no responsible role: <section: step (id), ...>
2. <n> roles own steps with no hourly rate: <role (steps owned), ...>
3. ...

## Weakens (<n>)
...

## Tidies (<n>)
...

## Proposed fixes, in order
| # | Fix | Steps or objects | Call | Needs from you |
|---|---|---|---|---|
| 1 | Set executor Person on 6 steps | <ids> | update_workflow | confirm |
| 2 | Rate for Operations Manager | role 412 | update_org | confirm $48/h (BLS median, loaded) |
...

👉 I need from you: <the confirmations and inputs, or "approve batch 1 to apply">
```

### The push plan

Every proposal that leads to a write ends with this block, before the approval question. Same three verbs every time, `Remove: nothing` spelled out, exact counts from the proposal above it, one sample row with every field the push will set.

```
Push plan: one batch of fixes
Add:     <n> <things> (<names, or the first five and "+n more">)
Change:  <n> <things> (<what changes on them>)
Remove:  <n> <things> (<names>)   or: nothing
Sample:  <one row as it will land, every field>
Nothing is written until you approve. Approve to push, or edit the list.
```

One block per approved batch, with the fix as the Change line and the step or object ids in the sample row. The push writes exactly what the block says. Anything discovered mid-push that is not in the block is reported, not pushed. When a push is split into batches, the block says "in N batches", one approval covers them, and a failed batch stops the rest and reports.

## Apply fixes

Only after the user approves, and one batch at a time:

- Step fields: `update_workflow` with `steps` (max 25 per call) and `connections` (labels, targets).
- Links: `link_to_steps` for roles, tools, attributes, assets; `unlink_from_steps` for dead links.
- Roles, rates, status and type: `update_org`. People to roles and their Details (active, end_date): `update_people`.
- Outstanding work the audit finds but cannot fix itself: `create_tasks` on the step or section it belongs to, named as the action ("Confirm the invoice approval limit with Finance"), so it shows on the map instead of only in the report.
- Tools: `update_account_tools` for status and cost items.
- Then re-run the checks on what changed and report the before and after counts.
- Then record the audit and its fixes as a changelog entry with `log-a-decision`: what was found, what was fixed, what was left and why.

## Rules

- Reading is free; writing waits for approval. A finding is never silently "fixed".
- Never invent a rate, a duration, a tool or an owner to close a gap. Propose, mark proposed, ask.
- Runs and charges are read, never edited, by this skill. Agents don't rename or delete runs; people do that in the app.
- Leave Archived content alone unless the user scopes it in.
- Report counts from a full page-through. "At least" when you stopped early, and say why.
- A clean audit is a result. Say "no blocks, three tidies" and stop; do not manufacture findings.
