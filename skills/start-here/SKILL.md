---
name: start-here
description: Begin with a Puzzle workspace. The install check and the readiness check to run the first time these skills point at a workspace, or whenever the user asks "where do I start", "set up my workspace", "I just installed the Puzzle skills", "what should we map first", "is my workspace ready", or "which skill do I use". Confirms the Puzzle MCP connection, finds the workspace owner, inventories the four canvases and the changelog, proposes the order of work (tools inventory, data model, assets, team with rates, people, first workflow) adjusted to what already exists, asks one question, and records a Workspace setup changelog entry that the later skills tick off. Not a gate: any other Puzzle skill can run first.
---

# Start here

Ten skills and a README with role bundles still leave one question inside the chat: which first, for this workspace, in its current state. This skill answers it by reading the workspace, not by asking the user what the workspace already says. It runs once per workspace, or any time someone wants their bearings.

It is not a gate. A user who says "map this process" into an empty workspace gets `build-puzzle-process`, which creates the roles and tools it needs as it goes. `start-here` is for "where do I begin".

## 1. The install check

1. Call `list_tabs` with no arguments. A response with four canvases means the Puzzle MCP is connected and this is a workspace. An error means the connector isn't set up: say so, point at the MCP link in the Puzzle app (Settings) and stop.
2. If more than one Puzzle server is connected, name them and ask which workspace this is about. Never guess.
3. Find the owner: `list_people` with `query` for the user's name, or ask. Every changelog entry later needs a `person_id`. If the user isn't on the People canvas, offer to add them (`create_people`) before anything else; a workspace with no owner has no one to log decisions.

## 2. The readiness check

Read the four canvases and the record, in as few calls as the workspace allows:

| Area | Calls | What you're counting |
|---|---|---|
| Tools | `list_tools` scope `workspace`, `include: ["status", "cost_items", "tool_group_name"]` | tools; tools with any cost item; tool groups |
| Data model | `list_entities`, `include: ["attribute_count", "step_count", "tool_name"]` | entities; attributes; entities linked to any step |
| Assets | `list_assets`, `include: ["type", "step_count"]` | assets; assets linked to any step |
| Team | `list_teams`, `include: ["role_count"]`; `list_roles`, `include: ["hourly_rate", "step_count", "people.person_id"]` | teams; roles; roles with a rate; roles with a person |
| People | `list_people`, `include: ["role_count", "person_type"]` | people; people holding a role |
| Workflows | `list_tabs` canvas `workflows`; `list_sections` per tab, `include: ["step_count"]` | tabs; sections; steps; Archived tabs set aside |
| Record | `list_changelog_entries`, `include: ["status"]`; `list_shared_views` | entries by status; shared views |

Page through; `meta.total` is the count. Treat a canvas as **empty** at zero, **started** below roughly a dozen items or with most of them missing a key field (rates, costs, links), and **in use** otherwise.

## 3. The order, and why

Every step in a workflow links a tool and a role, and reads or writes a record. Build the things steps point at before the steps, so the first process lands complete instead of needing a second pass.

1. **Tools inventory** (`map-tools-and-data`, tools part). Always first. Every step names a system; the Tools canvas is where the operation's cost lives.
2. **Data model** (`map-tools-and-data`, entities and attributes). The records and fields the steps will read and write.
3. **Assets** (`map-tool-assets`). What lives inside the tools that steps run from: boards, templates, reports, automations, videos.
4. **Team** (`map-the-team`, teams and roles). Roles with hourly rates, because every Person step is owned by a role and costed by its rate.
5. **People** (`map-the-team`, people). The humans in the roles, after the roles exist.
6. **First workflow** (`interview-for-a-process` if it has to come out of someone's head, then `build-puzzle-process`). Pick the process the user cares about most, or the one the most people touch.
7. **Then the loop**: `log-a-decision` every time something changes, `audit-the-map` before a review, `cost-a-process` and `find-automation-opportunities` once a current state exists.

Adjust to the state. A canvas in use is skipped, with its gaps noted for `audit-the-map`. A canvas started but thin is listed as "finish, then move on". An empty workspace gets the full order.

## 4. One question

Present the readiness picture and the proposed path, then ask one thing: start with the recommended step, or pick another. Lead with the recommendation and the reason.

```
# <Workspace>: where things stand
Tools: 14, 3 with costs, 2 groups · Data: 6 entities, 41 attributes, 0 linked to steps · Assets: 0
Team: 3 teams, 9 roles, 2 with rates, 4 with people · People: 6, 4 in roles
Workflows: 2 tabs, 5 sections, 38 steps · Changelog: 3 entries · Shared views: 1

## Recommended path
1. Finish the tools inventory: 11 tools have no cost, and the map can't price a step without them. (map-tools-and-data)
2. Rates on 7 roles. (map-the-team)
3. Link the 41 attributes to the steps that read and write them. (map-tools-and-data)
4. Assets for the 5 tools the 38 steps use most. (map-tool-assets)
5. First new workflow, or an audit of the 5 you have. (build-puzzle-process / audit-the-map)

Start with 1, since every later figure depends on it. Or tell me which to take first.
```

## 5. Record the setup

After the user picks, create a changelog entry through `log-a-decision`: title "Workspace setup", status planned, owner from step 1. The body carries the readiness picture as found and the path as a numbered checklist. Each later skill that completes a step updates the entry (`update_changelog_entries`): tick the item, link the steps and tools it touched. When the list is done, the entry goes to completed. The onboarding is itself in the changelog, which is where the history of the workspace lives.

## Rules

- Read first, ask once. Never ask the user for a count the workspace can give you.
- Recommend; don't gate. The user can start anywhere, and every other skill works without this one.
- Empty means unknown, not wrong. A thin canvas is a to-do, not a criticism.
- Nothing is written in this skill except the owner (if the user agrees) and the setup entry (after the user picks).
- Keep the picture to one screen. The audit skill is for the long list.
