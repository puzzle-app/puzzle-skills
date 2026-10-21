---
name: read-the-map
description: Read a Puzzle workspace through the Puzzle MCP and answer questions from it. Load first, before any other Puzzle skill, and whenever the user asks what a process does, who owns a step, which steps use a tool, what data a step reads or writes, what something costs, why a decision was made, what is outstanding, or what is shared publicly. Covers the four canvases (Workflow, Team, People, Tools and data model), the changelog, tasks and shared views, the list_* calls and the include fields each answer needs, how to put steps back in flow order from their connections, the tool_id versus account_tool_id trap, and how to answer from the map without inventing anything it does not say.
---

# Read the map

Everything an agent does in Puzzle starts with reading the workspace well. This skill is the foundation the other Puzzle skills assume: how the map is organised, which call answers which question, what to include so the answer is complete, and how to report what the map says without padding it.

## What a workspace holds

Four canvases, a changelog, tasks and shared views. Everything links to everything that touches it.

| Thing | Lives on | What it is |
|---|---|---|
| Tab | every canvas | A view that groups content: Onboarding, Sales, Current State, Future State. Each canvas has its own tabs. |
| Section | Workflow | One process. Holds steps and their connections. Has a description and notes. |
| Step | Workflow | One activity. Carries a type (task, email, form, conditional, delay, go_to, subflow, and more), a status (Draft, In_Progress, Testing, Live, Archived), an executor (Person, Automation, AI Agent), roles with RACI involvement, tools, attributes, assets, duration in minutes, frequency per month, and notes. |
| Connection | Workflow | An arrow from one step to the next, with an optional label (the outcome of a conditional, a timing). |
| Team and role | Team | A role is a position with an hourly rate; a team groups roles; role connections are reporting lines. Steps are owned by roles. |
| Person | People | A human (or an AI agent) who holds one or more roles and has access to tools. |
| Tool and tool group | Tools | A system the operation runs on, with its costs and status. Groups organise tools. |
| Entity and attribute | Tools (data model) | The records a tool holds (Contact, Deal, Ticket) and their fields. Attributes link to the steps that read or write them, as trigger, input or output. |
| Asset | Tools | A template, report, document, video or snippet kept inside a tool, with a URL, linked to the steps that use it. |
| Task | Workflow | A checklist item on a step or section, outstanding or completed. |
| Changelog entry | Changelog | A decision or change: body with the rationale, owner, status (idea, planned, in_progress, completed, archived), linked steps and tools. |
| Shared view | Workspace | A public, curated subset of the map: selected sections, teams, tool groups, people tabs or people. |

The map is a model the team maintains. It describes the operation as the team has documented it, not as a live system reports it. Say "the map says" when the distinction matters.

## How the MCP returns data

- Every `list_*` call returns a minimal base per record, usually `{id, name, url}`. Every other field is opt-in through `include`. A field missing from a response means you did not ask for it, not that it is empty.
- Pass `id` with `include` to get one record in full.
- Dot notation picks nested sub-fields: `roles.role_name`, `connections.to_step_id`. Nested arrays (roles, tools, connections, attributes) are heavier than scalar fields; include what the question needs.
- Lists paginate. `meta.total` tells you how many exist; page through with `page` and `page_size` before saying "there are N".
- Responses come as `{"ok": true, "data": [...]}` or `{"ok": false, "errors": [...]}`. Read the error before retrying.
- `url` is a path inside the app (`/workspaces/1/steps/123/edit`). Prefix it with the app origin, `https://app.puzzleapp.io`, when giving the user a link. A shared view's `url` is its public path (`/share/1/<slug>`).
- Names and notes can carry HTML from the editor: `<p>` wrappers and `<span data-type="mention" data-label="Webflow">` mentions of tools, roles and people. Strip the tags and keep the label text when you report them; the mentions tell you which tool or role the author linked inline.
- `hourly_rate` on a role comes back as an object, `{"amount": "50.00", "currency": "USD"}`, or `null` when unset. Use the amount as a number and keep the currency.
- `field_type` on an attribute can be `null` when the author never set it; treat that as "untyped", not as text.

### The two tool ids

`list_tools` with scope `workspace` returns both `id` (the catalogue tool id) and `account_tool_id` (this workspace's copy). They are different numbers and different calls want different ones:

- `tool_id` (catalogue id): `list_steps` filter, `link_to_steps`, `create_process` and `create_tool_structure`.
- `account_tool_id` (workspace id): `list_people`, `list_entities`, `list_attributes`, `list_assets` filters, `update_account_tools`, `update_changelog_entries`, `create_data_model`, `create_assets`.

Resolve several tools in one call with a comma-separated query: `"Attio, QuickBooks, Intercom"`.

## Which call answers which question

**What processes exist, and where.** `list_tabs` with canvas `workflows`, then `list_sections` per tab with `include: ["step_count", "description"]`. Archived tabs and sections are history unless the user asks about them.

**Walk me through this process.** `list_sections` with `query`, then `list_steps` with `section_id` and `include: ["type", "status", "executor", "notes", "duration", "frequency", "roles.role_name", "roles.involvement", "tools.tool_name", "connections.connection_id", "connections.to_step_id", "connections.to_step_name", "connections.label"]`. Steps come back unordered; put them in flow order (next section). For a `go_to`, `alias` or `subflow` step, add `target` to see where it points.

**Who does this, and who signs off.** The roles on the step with `roles.role_name` and `roles.involvement` (responsible, approver, consulted, informed). To find every step a role owns: `list_steps` with `role_id`. To find the humans in a role: `list_roles` with `include: ["people.first", "people.last", "team_name", "hourly_rate"]`. To go from a person to their roles: `list_people` with `include: ["roles.role_name", "team_names"]`.

**What runs on this tool, and what breaks if we change it.** Resolve the tool with `list_tools` scope `workspace`. Then: `list_steps` with `tool_id` (catalogue id) for the steps; `list_entities` and `list_attributes` with `account_tool_id` for the data; `list_assets` with `account_tool_id` for the templates and reports kept in it; `list_people` with `account_tool_id` for who has access. The union is the blast radius of a change to that tool. Report it as steps, records, assets and people, each with counts.

**What data does this step read or write.** `list_attributes` with `step_id` and `include: ["entity_name", "tool_name", "field_type", "steps.kind"]`. `kind` is trigger, input or output per step.

**What does this cost.** Labor per step per month is duration in minutes divided by 60, times frequency, times the responsible role's hourly rate (from `list_roles` with `hourly_rate`). Tool costs come from `list_tools` scope `workspace` with `include: ["cost_items"]`. A step missing duration, frequency or a rated role has no labor figure; say so rather than estimating. The `cost-a-process` skill carries the full model.

**Why is it like this.** `list_changelog_entries` with `query` (matches body text) or with `include: ["associated_steps.step_name"]` to find the entries behind a step. Read `body`, `status`, `completed_at`, `owner_name`. The changelog is the record of decisions; a step with no entry behind it has no recorded reason, and that is the honest answer.

**What is outstanding.** `list_tasks` with `completed: false` and `include: ["step_name", "section_name"]`, filtered by `section_id` or `step_id` when the question is scoped.

**What is public.** `list_shared_views` with `include: ["description", "slug", "password_protected", "items.type", "items.name"]`. A shared view is the only part of a workspace a non-member can see.

**Who reports to whom.** `list_teams` with `include: ["roles.name", "role_connections.from_role_name", "role_connections.to_role_name", "role_connections.label"]`. Person-to-person connections live on `list_people` with `connections.*`.

## Putting steps in flow order

Steps arrive as a set, not a sequence. Rebuild the sequence from connections:

1. Each step returns `connections_in` and `connections_out` arrays (with `connection_id`, `label`, and the other step's id and name). Collect every connection as (from, to, label).
2. The step whose `connections_in` is empty is the trigger. Several means several entry points; say so.
3. Walk forward. At a `conditional` step, each outgoing connection is an outcome; use its label ("Yes", "No", "matched") as the branch name. A branch that reaches a step with no outgoing connection has ended there; a `go_to` step's `target` says where the flow jumps.
4. A `subflow` step runs another section; name it and, if the user asked for depth, read that section the same way.
5. A `delay` step is wait time; carry its duration into the walk-through.
6. When two branches enter the same step, the paths rejoin there.

Report the walk-through as the trigger, the main path in order, and each branch under the conditional that opens it. Name the executor and the responsible role on every step; name the tool where there is one.

## Answering rules

- Answer from the workspace, with step names and ids, so the user can click through. Never describe a step the list did not return.
- Distinguish what the map says from what is true in the business. The map can be stale; the changelog and the step status are the clues. A step with status Draft or Testing is not running today.
- A missing field is a finding, not a blank to fill. "Seven of the twelve Person steps have no duration" is more useful than an invented total.
- Executor tells you who does the work: a Person step is manual, an Automation step is software, an AI Agent step is an agent. Do not call an Automation step "someone".
- Steps are owned by roles. If asked who does a step, answer with the role, then the person currently in it if the user wants a name.
- Count before you quantify. `meta.total` and a full page-through, or say the number is "at least".
- Keep the user's vocabulary. If their section is called "Order to cash", do not rename it.
- Reading is free; nothing in this skill writes. The build, team, tools, decision and audit skills do the writing, each after the user approves a proposal.

## Output shapes

A walk-through:

```
# <Section name> (<tab>), <n> steps, <n> Live
Trigger: <step> (<executor>, <role>, <tool>)
1. <step> (<executor> · <role> · <tool>) <one line from the note>
2. <conditional>: <question>
   ✅<label> → 3a. ... → rejoins at 5
   ❌<label> → 3b. ... → ends: <terminator>
...
Open: <steps missing executor / role / tool / cost inputs, if any>
Decisions behind it: <changelog entries by title and id, or "none recorded">
```

A tool impact answer:

```
# <Tool>: what depends on it
Steps: <n> across <n> sections (<list the sections>)
Records: <entities and attribute counts>
Assets: <n> (<types>)
People with access: <n>
Changelog: <entries that touched this tool>
```

## Before you build anything

Read first. Every write skill in this set opens with `list_tabs`, the relevant `list_sections`, `list_teams`, `list_tools` and `list_entities`, so it adds to what exists instead of duplicating it. If a question turns into a change ("can you fix that"), the answer is a proposal in chat, then the matching skill.
