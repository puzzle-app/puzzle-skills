---
name: start-here
description: Begin with a Puzzle workspace, and round it out. Load the first time these skills point at a workspace, or whenever the user asks "where do I start", "set up my workspace", "round out the workspace", "fill in what's missing", "I just installed the Puzzle skills", "what should we map first", "is my workspace ready", or "which skill do I use". Mode one reads the workspace and says where things stand. Mode two runs the round-out pass: five stages in order (tools, data model, assets, team, people), each one read what Puzzle's onboarding and the connected systems already hold, propose the fill-in with a push plan, push only on approval, verify, tick a Workspace changelog entry, continue or stop; then round out the first map and offer the next process or an opportunity analysis. Never removes anything. Not a gate: any other Puzzle skill can run first.
---

# Start here

Nobody arrives at an empty workspace. Puzzle's own onboarding has already created the tools picked from the gallery, the teams and roles from an uploaded org chart, the people cards, a workflow tab per team, and usually a first process Nova built from a description, with an onboarding changelog entry recording it. What onboarding does not do is the depth: tool costs and groups, entities and attributes, assets, hourly rates, reporting lines, tool access per person, and the executors, cost inputs, attributes and handles on that first map.

This skill has two modes. **Where am I** reads the workspace and says where things stand. **Round out the workspace** fills in what onboarding leaves, stage by stage, with a push plan and an approval before every write. It is not a gate: `build-puzzle-process` and every other skill run on their own at any time.

Load `read-the-map` first. `references/sources.md` says what each connected system can give each stage.

## Mode one: where am I

### The install check

1. `list_tabs` with no arguments. Four canvases back means the Puzzle MCP is connected and this is a workspace. An error means the connector isn't set up: say so, point at the MCP link in the Puzzle app and stop.
2. More than one Puzzle server connected: name them and ask which workspace. Never guess.
3. The owner: `list_people` with `query` for the user's name, or ask. Every changelog entry needs a `person_id`. If the user isn't on the People canvas, offer to add them (`create_people`) before anything else.

### The readiness check

Read the onboarding changelog entry first (`list_changelog_entries` with `query: "onboarding"`, `include: ["body", "status", "completed_at"]`): it says what Nova created and from which inputs. Then count, in as few calls as the workspace allows:

| Area | Calls | Counting |
|---|---|---|
| Tools | `list_tools` scope `workspace`, `include: ["status", "cost_items", "tool_group_name"]` | tools; with any cost item; groups |
| Data model | `list_entities`, `include: ["attribute_count", "step_count", "tool_name"]` | entities; attributes; linked to any step |
| Assets | `list_assets`, `include: ["type", "step_count"]` | assets; linked to any step |
| Team | `list_teams`, `include: ["role_count", "role_connections"]`; `list_roles`, `include: ["hourly_rate", "step_count", "people.person_id"]` | teams; roles; with a rate; with a person; reporting lines |
| People | `list_people`, `include: ["role_count", "person_type", "tools"]` | people; holding a role; with tool access |
| Workflows | `list_tabs` canvas `workflows`; `list_sections` per tab, `include: ["step_count"]`; for the first map, `list_steps` with `include: ["executor", "duration", "frequency", "roles.role_id", "tools.tool_id"]` | tabs; sections; steps; on the first map, steps missing executor, role, cost inputs or tool |
| Record | `list_changelog_entries`, `include: ["status"]`; `list_shared_views` | entries by status; shared views |

Page through; `meta.total` is the count. A canvas is **as onboarding left it** when it has objects but the depth fields are empty, **in use** when most depth fields are filled, **empty** at zero.

### The picture, and one question

```
# <Workspace>: where things stand
Onboarding (2026-10-20): 14 tools from the gallery, 3 teams and 9 roles from the org chart, 6 people, 1 process Nova built (38 steps)
Tools: 14, 0 with costs, 0 groups · Data: 0 entities · Assets: 0
Team: 9 roles, 0 with rates, 4 with people, 2 reporting lines · People: 6, 4 in roles, 0 with tool access
First map "Client onboarding": 38 steps, 31 without executor, 38 without cost inputs, 0 attributes, 12 without a tool

## Round-out path
1. Tools: costs on 14, missing tools from your connected systems (map-tools-and-data)
2. Data model: the records your connected CRM and billing system hold (map-tools-and-data)
3. Assets: boards, templates, automations from Monday, Attio, Zapier (map-tool-assets)
4. Team: rates on 9 roles, reporting lines (map-the-team)
5. People: 2 without a role, tool access (map-the-team)
6. First map: audit and fix "Client onboarding", then build the next or analyze this one

Start the round-out at 1, or pick a stage. Each stage shows a push plan before anything is written.
```

A stage with nothing to fill is listed as "already in place". A workspace with no gaps anywhere gets `audit-the-map` instead of the pass.

## Mode two: round out the workspace

### How every stage runs

1. **Read** what the canvas holds and what the sources can add (`references/sources.md`). Match source names to canvas names first; a near-match is shown as a match to confirm, never as an Add.
2. **Propose** the fill-in through the stage's skill, ending with its push plan: Add, Change, Remove (always "nothing" here), exact counts, one sample row, "nothing is written until you approve".
3. **Approve.** One approval per stage. An edited proposal is re-proposed in full. Nothing is pushed on a partial answer.
4. **Push** through the stage's skill, in its batches, reporting each batch as it lands. Anything discovered mid-push that is not in the plan is reported, not pushed.
5. **Verify** with the skill's own verify step; report counts and ids.
6. **Tick** the stage on the Workspace entry (`update_changelog_entries`: the body line, the tools touched), then one line of progress and the choice: continue to the next stage, or stop here.

Stopping is fine. The Workspace entry holds the state; "continue the round-out" later reads it and resumes at the first unticked stage. No state anywhere else.

### Stage 1: round out the tools

Onboarding left the gallery picks. Add the tools the connected systems show that aren't on the canvas, and any a step names. Change: status on each, costs where a source states them (list price marked as such; an unconfirmed cost is not pushed), groups only past twelve tools. Through `map-tools-and-data`.

### Stage 2: data model

Onboarding creates none. Entities and attributes only for tools in the inventory, only the records the operation uses, read live from a connector's schema where one exists (a CRM's attribute definitions, a board's columns, a billing system's objects), otherwise from the user. No default templates: a record the user's steps don't touch is noise. Through `map-tools-and-data`. Attribute-to-step links come with stage 6.

### Stage 3: assets

Onboarding creates none. What lives inside the connected tools, with the type mapping and verified URLs, matched to steps where steps exist. Batches of 60. Through `map-tool-assets`, which keeps its own running entry and reports counts back.

### Stage 4: round out the team

Onboarding left teams and roles from the org chart, without rates. Change: an hourly rate on every role, proposed as the average base salary for the title and region divided by 2,080, basis stated, confirmed in the proposal; reporting lines where thin; a note on what each role owns. Add: roles that steps name but the canvas lacks. Through `map-the-team`.

### Stage 5: round out the people

Onboarding left people cards. Sources in order: the existing people; the Google Workspace directory and the Slack user list where those connectors are present (Puzzle has no directory connector of its own); a CSV; LinkedIn, searched for people at the company, as a recommendation list the user confirms name by name, public titles only; the user. Change: a role on every person who holds none, type and email where blank, tool access from stage 1 where a source states it. Add: missing people, confirmed. Batches of 50. Through `map-the-team`.

### Stage 6: the first map, then the next thing

Onboarding usually left one process Nova built. Round it out first: `audit-the-map` on that section, then the fixes in one approved batch per kind, through `update_workflow` and `link_to_steps`: an executor on every step; a responsible role on every Person step; duration and frequency on every Person step; attributes on every step that reads or writes data; a tool on every step that happens in one; the two-call handle pass from `build-puzzle-process` (default on every connection, then the exceptions). Then the entry's last item offers two paths and records the pick:

- **Build the next process**: `interview-for-a-process` if it has to come out of someone's head, then `build-puzzle-process`.
- **Analyze this one for opportunities**: `find-automation-opportunities`, with `cost-a-process` for the figures.

### The Workspace entry

Created when the user starts the pass, through `log-a-decision`: title "Workspace rounded out", status planned, owner from the install check, linked to the onboarding entry as its starting point. Completed when stage 5 is ticked. Body:

```
# Workspace rounded out
Owner: <name> · Started: <date> · Sources: <connectors and files used>

## As onboarding left it
<the readiness picture, with the onboarding entry cited>

## Stages
- [x] 1 Tools: 3 added, 14 now with costs, 2 groups (2026-10-23, from Attio, Monday, invoices.csv)
- [ ] 2 Data model
- [ ] 3 Assets
- [ ] 4 Team: rates on 9 roles, reporting lines
- [ ] 5 People: role on 2, tool access
- [ ] 6 First map "Client onboarding": rounded out | next: build "<name>" or analyze

## Decisions made along the way
- Rates are base salary ÷ 2,080, not loaded (<who>, <date>)
```

## What this skill never does

- Push without a push plan and an approval on it.
- Remove anything. Rounding out adds and changes; what onboarding created is never deleted here. A duplicate it created itself in the same run is proposed for removal and pushed only on an explicit yes.
- Write to a source system. Connectors are read.
- Invent a cost, a rate, a URL, a field type, or a person's role. Gaps are asked about or left for `audit-the-map`.
- Push anything from LinkedIn on its own. It is a recommendation list.
- Gate the other skills. "Map this process" into a half-filled workspace still gets `build-puzzle-process`, which creates the roles and tools it needs as it goes.

## Rules

- Read first, ask once per stage. Never ask the user for a count the workspace can give you.
- Recommend; don't gate.
- Empty means unknown, not wrong. A thin canvas is a to-do, not a criticism.
- Keep the picture to one screen. The audit skill is for the long list.
- The Workspace entry is the only state. If it says a stage is done, it is done; re-run `audit-the-map` to find what drifted since.
