---
name: map-the-team
description: Build or extend the Team and People canvases of a Puzzle workspace through the Puzzle MCP: teams, roles with hourly rates, reporting lines, the people in each role, and the tools each person can access. Load when the user asks to "map the team", "add our org chart", "set up roles", "who reports to whom", "add hourly rates", "put people in roles", "add a new hire", or when a process build names a role that doesn't exist yet. Covers one intake round, rate research with the basis stated, roles versus people, hierarchy that drives the auto-layout, and a changelog entry at the end.
---

# Map the team

Steps in Puzzle are owned by roles, costed by the role's hourly rate, and staffed by the people in the role. A workflow map with no team behind it answers "what happens" but not "who" or "how much". This skill builds the Team canvas (teams, roles, rates, reporting lines) and the People canvas (people, their roles, their tool access) so every other skill has owners and rates to work with.

Load `read-the-map` first.

## Roles, not people, and why

- A **role** is a position: Operations Manager, Account Executive, Bookkeeper. It owns steps and carries the hourly rate. Roles persist when people change.
- A **person** is a human (or an AI agent, with `person_type: ai_agent`) who holds one or more roles. A person links to steps only through a role.
- A **team** groups roles: Sales, Finance, Delivery. Reporting lines are connections between roles, and they are what the layout engine uses to draw the chart.
- A solo operator is one person holding several roles. Map the roles anyway; the costing and the future-state planning depend on knowing which hat does which step.

## Read before you write

1. `list_tabs` with canvas `teams` and canvas `people`. Pick the tab or confirm it with the user.
2. `list_teams` with `include: ["roles.id", "roles.name", "role_connections.from_role_name", "role_connections.to_role_name"]`. What already exists must be extended, never recreated.
3. `list_roles` with `include: ["hourly_rate", "team_name", "step_count", "people.first", "people.last"]`. Note roles without rates and roles without people.
4. `list_people` with `include: ["email", "person_type", "roles.role_name", "tools.tool_name"]`.
5. `list_tools` scope `workspace` for the tools people will get access to.

## The single intake round

Draft the whole structure from what the user gave you (an org chart, a list of names and titles, a description, a process that names roles), then ask everything missing once:

- **Teams**: which teams, and which roles sit in each. Roles that belong to no team go in `standalone_roles`.
- **Reporting lines**: who reports to whom, by role. Infer from titles (a Manager over a Coordinator) and present the inference for confirmation.
- **Rates**: for every role without an hourly rate, research a figure before asking. Use a public salary source for the title and region, convert salary to hourly on 2,080 hours a year, state whether it is base or loaded (base × 1.25 to 1.4 for benefits and overhead), and present it as "confirm or correct". Never create a rate-less role.
- **People**: name, email, type (employee, contractor, vendor, advisor, board_member, intern, volunteer, ai_agent), and which roles each holds. If a person is named with no role, ask what role they hold.
- **Tool access**: which workspace tools each person uses, if the user wants access mapped.
- **Layout**: `top_to_bottom` for an org chart (the default), `left_to_right` for a flat team with few levels.

Present the proposal as two tables, then stop for approval:

```
## Teams and roles
| Team | Role | Rate ($/h) | Basis | Reports to | People |
|---|---|---|---|---|---|
| Sales | VP Sales | 96 | $200k base ÷ 2080 | CEO | Maria L. |
| Sales | Account Executive | 48 | $100k base ÷ 2080 | VP Sales | 2 (names) |

## People
| Person | Type | Email | Roles | Tools |
|---|---|---|---|---|
```

## Build

1. **Teams and roles in one call.** `create_org_structure` with `teams` (new teams with nested `roles`, each with `hourly_rate` and `notes`), `standalone_roles`, and `connections` between role `temp_id`s for the reporting lines. Set `direction`. To add roles to an existing team, pass `team_id` and omit `name`. Reporting lines between existing roles go through `create_role_connections`, using their ids.
2. **People.** `create_people` with `people` (first, last, email, person_type) and, if the user wants a people chart, `connections` between person `temp_id`s. Capture the returned ids.
3. **Put people in roles and give tool access.** `update_people` with `add_role_ids` and `add_account_tool_ids` per person. Existing people get the same call; roles they already hold are skipped.
4. **Rates on existing roles.** `update_org` with `roles: [{id, hourly_rate}]`. Move a role between teams with `team_id`; make it standalone with `remove_from_team`.
5. **Notes.** Each role's note says what the role owns in two lines and where the rate came from. Each team's note says what the team is for.

## Verify

- `list_roles` with `include: ["hourly_rate", "team_name", "people.first"]`: every role has a rate, every role meant to be staffed has a person.
- `list_teams` with `include: ["role_connections.from_role_name", "role_connections.to_role_name"]`: the reporting lines match the proposal.
- `list_people` with `include: ["roles.role_name", "tools.tool_name"]`: every named person holds the roles proposed.
- If steps already exist that should be owned by the new roles, link them now: `link_to_steps` with type role and involvement responsible (approver, consulted and informed where they apply).

## Log it

Create a changelog entry with `log-a-decision`: the teams and roles created, each rate and its basis, the reporting lines, the people added and their roles, and any role left vacant on purpose. Status completed, owner the person who asked.

## Rules

- Extend, never duplicate. A second "Sales" team or a second "Account Executive" role is a fragment.
- Never create a role without an hourly rate, and never state a rate without its basis.
- A person's name never goes on a step. The role owns the step; the person holds the role.
- Reporting lines are role to role. Person-to-person connections are for a people chart, not for ownership.
- Titles from the user's organisation win over generic ones. If they say "Ops Lead", the role is "Ops Lead".
- An AI agent that owns steps is a person of type `ai_agent` in a role, so the map shows which seat the agent fills and what it costs to run instead.
