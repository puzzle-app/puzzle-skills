---
name: map-the-team
description: Build or extend the Team and People canvases of a Puzzle workspace through the Puzzle MCP: teams, roles with hourly rates, reporting lines, the people in each role, and the tools each person can access. Load when the user asks to "map the team", "add our org chart", "set up roles", "who reports to whom", "add hourly rates", "put people in roles", "add a new hire", or when a process build names a role that doesn't exist yet. Covers one intake round, rate research with the basis stated, roles versus people, hierarchy inferred from title seniority and team, top-to-bottom org and people charts whose reporting lines run from the manager's bottom handle to the report's top handle, and a changelog entry at the end.
---

# Map the team

Steps in Puzzle are owned by roles, costed by the role's hourly rate, and staffed by the people in the role. A workflow map with no team behind it answers "what happens" but not "who" or "how much". This skill builds the Team canvas (teams, roles, rates, reporting lines) and the People canvas (people, their roles, their tool access, and the people chart) so every other skill has owners and rates to work with.

Load `read-the-map` first.

## Roles, not people, and why

- A **role** is a position: Operations Manager, Account Executive, Bookkeeper. It owns steps and carries the hourly rate. Roles persist when people change.
- A **person** is a human (or an AI agent, with `person_type: ai_agent`) who holds one or more roles. A person links to steps only through a role.
- A **team** groups roles: Sales, Finance, Delivery. Reporting lines are connections between roles, and they are what the layout engine uses to draw the org chart. Person-to-person connections draw the people chart the same way. They are not ownership.
- A solo operator is one person holding several roles. Map the roles anyway; the costing and the future-state planning depend on knowing which hat does which step.

## Read before you write

1. `list_tabs` with canvas `teams` and canvas `people`. Pick the tab or confirm it with the user.
2. `list_teams` with `include: ["roles.id", "roles.name", "role_connections.id", "role_connections.from_role_name", "role_connections.to_role_name"]`. What already exists must be extended, never recreated. A manager-report pair that already has a line is not given another.
3. `list_roles` with `include: ["hourly_rate", "team_name", "step_count", "people.first", "people.last"]`. Note roles without rates and roles without people.
4. `list_people` with `include: ["email", "person_type", "roles.role_name", "tools.tool_name", "connections.connection_id", "connections.from_person_name", "connections.to_person_name", "connections.label"]`.
5. `list_tools` scope `workspace` for the tools people will get access to.

## The single intake round

Draft the whole structure from what the user gave you (an org chart, a list of names and titles, a description, a process that names roles), then ask everything missing once:

- **Teams**: which teams, and which roles sit in each. Roles that belong to no team go in `standalone_roles`.
- **Reporting lines**: do not require a reports-to. Use one the user stated, by name or by title; a stated line wins over a guess. Otherwise infer from title seniority and team, for roles and for people. Rank within the team: C-level, founder, or owner; then VP, head, or director; then manager or lead; then senior; then the individual contributor; then coordinator, associate, assistant, or intern. Each one reports to the nearest more-senior one in the same team. The most senior in a team reports to the nearest more-senior person outside it. Someone who is the top has no manager, and never a line to themselves. Same rank means peers: they share the manager above them, and no line joins them. One manager each, unless the user stated a second line. Ask one short question only when two candidates are equally senior and either could be the manager, and name the candidates. Do not ask when the rank names a single manager. Put every line in the Reports to column. Approving the push plan confirms the inference.
- **Rates**: for every role without an hourly rate, research a figure before asking. Use a public salary source for the title and region, convert salary to hourly on 2,080 hours a year, state whether it is base or loaded (base × 1.25 to 1.4 for benefits and overhead), and present it as "confirm or correct". Never create a rate-less role.
- **People**: name, email, type (employee, contractor, vendor, advisor, board_member, intern, volunteer, ai_agent), and which roles each holds. If a person is named with no role, ask what role they hold.
- **Tool access**: which workspace tools each person uses, if the user wants access mapped.
- **Layout**: org charts and people charts are always `top_to_bottom`. One row per level. Each manager's direct reports sit on the one row beneath that manager. No line crosses another line, and no line runs across a card. A flat team stays top to bottom. The layout engine places the cards from the connections and `direction`. There is no position field. Do not use `left_to_right`.

Before the proposal, walk the lines. A loop is an error: drop the inferred edge that closes it and say which one you dropped. Name every role and person with nobody above them. Co-leaders the user described stay as more than one top, with no line between them. Several tops that look like a missing manager are the one clarifying question, not a guessed edge.

Present the proposal as two tables, then stop for approval:

```
## Teams and roles
| Team | Role | Rate ($/h) | Basis | Reports to | People |
|---|---|---|---|---|---|
| Sales | VP Sales | 96 | $200k base ÷ 2080 | CEO | Maria L. |
| Sales | Account Executive | 48 | $100k base ÷ 2080 | VP Sales | 2 (names) |

## People
| Person | Type | Email | Roles | Reports to | Tools |
|---|---|---|---|---|---|---|
```

### The push plan

Every proposal that leads to a write ends with this block, before the approval question. Same three verbs every time, `Remove: nothing` spelled out, exact counts from the proposal above it, one sample row with every field the push will set.

```
Push plan: Team canvas, then a second block for the People canvas
Add:     <n> <things> (<names, or the first five and "+n more">)
Change:  <n> <things> (<what changes on them>)
Remove:  <n> <things> (<names>)   or: nothing
Sample:  <one row as it will land, every field>
Nothing is written until you approve. Approve to push, or edit the list.
```

One block for the Team canvas (teams, roles, rates, reporting lines, and the bottom-to-top handle pass on those lines) and one for the People canvas (people, reporting lines, the same handle pass, role assignments, tool access). When the sample row is a reporting line, it names the manager, the report, and handles bottom to top. The push writes exactly what the block says. Anything discovered mid-push that is not in the block is reported, not pushed. When a push is split into batches, the block says "in N batches", one approval covers them, and a failed batch stops the rest and reports.

## Build

`from` is the manager. `to` is the report. A reporting line leaves the bottom of the senior card and enters the top of the junior card. None of the create calls accept handles. On `create_org_structure` and `create_people` a connection is `from`, `to`, and `label`. On `create_role_connections` it is `from_role_id`, `to_role_id`, and `label`. On `create_person_connections` it is `from_person_id`, `to_person_id`, and `label`. `direction` on `create_org_structure` and `create_people` defaults to `left_to_right`, which is what lays the cards in a row and hooks the lines to the sides. Pass `top_to_bottom` on both. The two id-based connection calls have no `direction`. Handles are the next call, on the connection id.

1. **Teams and roles in one call.** `create_org_structure` with `teams` (new teams with nested `roles`, each with `hourly_rate` and `notes`), `standalone_roles`, `connections` between role `temp_id`s, and `direction: "top_to_bottom"`. One connection per manager-report pair, and none for a pair that already has a line. To add roles to an existing team, pass `team_id` and omit `name`. Reporting lines between existing roles go through `create_role_connections`, using their ids.
2. **Bottom to top on every role line.** `list_teams` with `include: ["role_connections.id", "role_connections.from_role_name", "role_connections.to_role_name"]`. `update_org` with one `role_connections` entry per reporting line: `{id, source_handle: "bottom", target_handle: "top"}`. `source_handle` and `target_handle` are `top`, `bottom`, `left`, or `right`. A reporting line uses `bottom` and `top` only.
3. **People.** `create_people` with `people` (first, last, email, person_type) and `direction: "top_to_bottom"`. When the proposal has people reporting lines, include `connections` between person `temp_id`s, one per pair. Capture the returned ids. Lines between people who already exist go through `create_person_connections`.
4. **Bottom to top on every people line.** `list_people` with `include: ["connections.connection_id", "connections.from_person_name", "connections.to_person_name", "connections.label"]`. Ids come back on `connections_in` and `connections_out` as `connection_id`. `update_people` with one `person_connections` entry per reporting line: `{id, source_handle: "bottom", target_handle: "top"}`.
5. **Put people in roles and give tool access.** `update_people` with `add_role_ids` and `add_account_tool_ids` per person. Existing people get the same call; roles they already hold are skipped.
6. **Rates on existing roles.** `update_org` with `roles: [{id, hourly_rate}]`. Move a role between teams with `team_id`; make it standalone with `remove_from_team`.
7. **Notes.** Each role's note says what the role owns in two lines and where the rate came from. Each team's note says what the team is for.

## Verify

- `list_roles` with `include: ["hourly_rate", "team_name", "people.first"]`: every role has a rate, every role meant to be staffed has a person.
- `list_teams` with `include: ["role_connections.id", "role_connections.from_role_name", "role_connections.to_role_name"]`: each role reporting line matches the proposal, `from` the manager and `to` the report, once. No line between peer roles. No loop.
- `list_people` with `include: ["roles.role_name", "tools.tool_name", "connections.connection_id", "connections.from_person_name", "connections.to_person_name", "connections.label"]`: every named person holds the roles proposed, and each people-chart line follows the same rule. Ids are `connection_id` on `connections_in` and `connections_out`.
- A pair the proposal listed once that now has two connections keeps one. `delete` the extra, type `role_connection` or `person_connection`. A peer line or a loop this run added is deleted the same way, and you say which. The chart is not done with a duplicate, a peer chain, or a cycle in it.
- Those reads return the connection id, the two ends, and the label. They do not return handles. Before reporting done, every reporting connection id from the read has been sent to `update_org` or `update_people` with `source_handle` `bottom` and `target_handle` `top`. Any id missing that update gets it now. A reporting line still on a side handle, or never set, means the chart is not done.
- If steps already exist that should be owned by the new roles, link them now: `link_to_steps` with type role and involvement responsible (approver, consulted and informed where they apply).

## Log it

When `start-here` called this skill as a stage of the round-out, also report back the counts and ids created or changed so it can tick the Workspace entry.


Create a changelog entry with `log-a-decision`: the teams and roles created, each rate and its basis, the reporting lines, the people added and their roles, and any role left vacant on purpose. Status completed, owner the person who asked.

## Rules

- Extend, never duplicate. A second "Sales" team or a second "Account Executive" role is a fragment.
- Never create a role without an hourly rate, and never state a rate without its basis.
- A person's name never goes on a step. The role owns the step; the person holds the role.
- Reporting lines are role to role on the org chart. Person-to-person connections are the people chart, not ownership.
- A reporting line runs from the manager's bottom handle to the report's top handle. Never left or right. Side handles chain peers sideways, and the chart stops reading as a tree.
- No line between peers. Exactly one line per manager-report pair. Org charts and people charts stay `top_to_bottom`: one row per level, that manager's reports on the row beneath, nothing crossing.
- Titles from the user's organisation win over generic ones. If they say "Ops Lead", the role is "Ops Lead".
- An AI agent that owns steps is a person of type `ai_agent` in a role, so the map shows which seat the agent fills and what it costs to run instead.
