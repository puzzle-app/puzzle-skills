---
name: brief-a-role
description: Write the brief for one role from a Puzzle workspace, in "you" voice, for the person stepping into it: what you own, where your work comes from and goes, every process you touch with your steps in order, the tools and the templates you'll use, what runs automatically around you, the known friction, and who to ask. Load when the user asks to "onboard [name]", "write an onboarding brief for [role]", "a new hire is starting as [role]", "what does the [role] do here", "hand this role over", or "explain this role to someone new". Reads the whole section around each step, never only the role's own steps. Short briefs inline; longer ones as a document, with a shared view offered for the processes it names.
---

# Brief a role

A role on the Team canvas owns steps across the map. A person stepping into that role needs the map read back to them from their seat: not the whole operation, and not a list of their steps in isolation, but each process they touch, where their work comes from, where it goes, and what happens around it. This skill writes that brief. It works for a new hire, a handover, a contractor, or someone covering while a seat is empty.

Load `read-the-map` first.

## Read

1. The role: `list_roles` with `query` and `include: ["team_name", "notes", "step_count", "people.first", "people.last"]`. If the user names a person, `list_people` with `include: ["roles.role_id", "roles.role_name"]` to get their roles; brief one role at a time.
2. The role's steps: `list_steps` with `role_id` and `include: ["section_id", "section_name", "type", "status", "executor", "notes", "roles.role_name", "roles.involvement", "tools.tool_name", "connections.connection_id", "connections.to_step_id", "connections.to_step_name", "connections.from_step_id", "connections.from_step_name", "connections.label"]`. Note each step's involvement: the role may be responsible on some, approver or consulted on others.
3. The whole section for each process: `list_steps` with `section_id` and the same includes. A step makes sense only with what precedes and follows it. Put each section in flow order.
4. The team: `list_teams` with `include: ["roles.name", "role_connections.from_role_name", "role_connections.to_role_name"]` for who the role reports to and who reports to it.
5. The people in the roles around this one: approver, consulted and informed roles on the role's steps, and the people currently in them (`list_roles` with `include: ["people.first", "people.last"]`).
6. Tools and assets: `list_assets` with `step_id` for the role's steps (`include: ["type", "asset_url", "tool_name"]`), and the tools on each step.
7. Decisions: `list_changelog_entries` with `include: ["associated_steps.step_id", "status", "completed_at"]`, filtered to entries touching the role's steps, for the "why it works this way" lines and anything in progress.

Exclude Archived steps and sections. Skip hourly rates; a brief is not where pay lives.

## Write

In "you" voice, to the person in the role. Plain language. The map's words for processes, steps and tools, so what they read matches what they'll see.

```
# <Role> at <Company>: your brief
Team: <team> · You report to: <role> (<person>) · Reports to you: <roles>

## What you own
<Two to four sentences: the processes this role is responsible in, and the one outcome each exists for.>

## <Process 1>
Where it starts: <the trigger step, and who or what fires it>.
Your part:
1. <Your step> (<tool>) · after <previous step> by <role>, before <next step> by <role>. <One line from the note on how.>
2. ...
What runs on its own around you: <the Automation and AI Agent steps in this section, in one line each: what they do and what they hand you>.
Who you'll work with here: <approver, consulted, informed roles and the people in them>.
Known friction: <steps in Draft or Testing, notes that say "manual for now", "workaround", "waiting on">. <Honest, one line each.>
Why it's built this way: <one or two lines from the changelog entries that touch these steps, or "no decisions recorded">.

## <Process 2>
...

## Your tools
<Tool>: <what you do in it, in one line> · <the templates, boards, reports linked to your steps, as links>

## Who to ask
<Role (person)>: <for what>
```

Rules for the text:

- Only what the map says. A step with an empty note gets "the map doesn't say how yet; ask <role>", not an invented procedure.
- Friction is stated, not softened. A Draft step is "not running yet". A note that says "workaround" is quoted.
- Automated steps are explained so the person knows what to expect without doing it: what triggers it, what it produces, where it lands.
- One process per section. A role in five processes gets five sections, in the order the user ranks them or by step count.

## Length and delivery

- One or two processes: the brief goes inline in chat.
- Three or more: write it as a markdown document in the session's working folder, named `<role>-brief.md`, and give the path. Offer a shared view of the processes it covers through `share-the-map` with the audience "a new hire", so the person can click into the map from the brief.

## After writing

- Gaps the brief exposed (steps with no note, no tool, no executor) go to the user as a short list; `audit-the-map` fixes them.
- If the user wants the brief kept with the map, add it as an asset on the tool where the document lives (`create_assets`, type Document, linked to the role's steps) and log it with `log-a-decision`.

## Rules

- "You" voice, to the person. Not "the new hire should".
- Whole-section context for every step. Never a bare list of the role's steps.
- No rates, no costs, no other people's pay in the brief.
- Nothing invented. Empty is "the map doesn't say yet".
- One role per brief. A person with three roles gets three sections or three briefs, their choice.
