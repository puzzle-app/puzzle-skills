---
name: share-the-map
description: Share part of a Puzzle workspace with people who aren't in it, through the Puzzle MCP: create or extend a public shared view holding the sections, teams, tool groups, people tab or people an audience should see. Load when the user asks to "share this process", "make a shared view", "send this map to the team, the client or a new hire", "publish this", "who can see this", or says yes to the share offer at the end of a build. Derives the contents from the workspace (the sections, the teams whose roles own their steps, the tool groups their steps use), asks only who it is for, extends an existing view for the same audience instead of creating a second, checks for Draft work before anything goes public, verifies the public URL and logs it.
---

# Share the map

A shared view is the one part of a workspace a non-member can see: a public, read-only page at its own URL, holding a curated subset of the map. It is how a process reaches the team that runs it, a client who paid for it, or a new hire who has to learn it, without handing anyone the whole operation. This skill decides what goes in from the workspace, asks one question, and publishes only after the user approves.

Load `read-the-map` first.

## What a shared view holds

- **Items**: sections (one process each), teams (their roles), tool groups (their tools), a `people_tab` (everyone on that People canvas tab, now and later), or individual people. Workflow, Team and Tools tabs are not selected as tabs; their sections, teams and groups are.
- **A name, a slug and a description.** The slug is the URL: `/share/<workspace>/<slug>` on the app origin. The description is shown on the page, so it says who the view is for and what it covers.
- **Password protection** is set in the app, not through the MCP; `list_shared_views` reports whether a view has it.
- A view is public to anyone with the link. Say so every time one is created.

## Read

1. `list_shared_views` with `include: ["description", "slug", "password_protected", "items.type", "items.id", "items.name"]`. A view for the same audience already there gets extended, never duplicated.
2. For each section to share: `list_steps` with `section_id` and `include: ["status", "roles.team_id", "roles.team_name", "tools.tool_id", "tools.tool_name"]`. This gives the teams whose roles own the steps and the tools the steps use.
3. `list_teams` for the team ids; `list_tool_groups` with `include: ["tools.tool_id"]` to find which groups hold those tools.
4. `list_tabs` canvas `people` if people may be included.

## One question: who is it for

Everything else is derived. The audience decides what goes in:

| Audience | Sections | Teams | Tool groups | People |
|---|---|---|---|---|
| The team that runs it | the process | the teams whose roles own its steps | the groups its tools sit in | the people tab, so names show on the roles |
| A new hire | the process and the ones it hands to | their team and the teams it hands to | the groups its tools sit in | the people tab |
| A client | the process(es) they paid for | only if they asked to see roles | only if they asked to see the stack | no, unless they ask |
| A partner or vendor | the process they take part in | no | no | no |

If the user said who it's for when they asked, don't ask again. If a view for that audience exists, propose adding to it.

## Propose, then publish

Show, and stop for approval:

```
Shared view: <name> (new | extend "<existing>")
URL: https://app.puzzleapp.io/share/<workspace>/<slug>
For: <audience>
Includes: <n> sections (<names>), <n> teams (<names>), <n> tool groups (<names>), people: <yes: tab name | no>
Description: <one sentence shown on the page>
Draft work inside: <none | n steps in Draft or Testing in <section>>
```

A section with Draft or Testing steps goes public only if the user says so after seeing the count. The audit skill flags the same thing later.

## Build

- New view: `create_shared_view` with `name`, `slug` (lowercase, hyphens, unique in the workspace), `description`, and `items` as `[{type, id}]`.
- Existing view: `list_shared_views` with its `id` and `include: ["items.type", "items.id"]` first, then `update_shared_view` with the **complete** `items` list, the existing ones plus the new ones. The call replaces the whole selection; passing only the additions removes everything else.

## Verify

`list_shared_views` with the view's `id` and `include: ["slug", "items.type", "items.name"]`: every item as proposed, the slug as expected. Give the user the public URL and remind them it is public to anyone with the link, and where to add a password in the app if the audience calls for one.

## Log

Add the view to the changelog entry of the build it shares (`update_changelog_entries`: the view's name, audience, URL and items in the body), or create an entry through `log-a-decision` when the view stands alone. Sharing is a decision about who sees what; it belongs in the record.

## After a build

`build-puzzle-process` ends its closing message with a one-line offer to share. This skill is what runs on a yes. It is never a question before the build, and never a gate.

## Rules

- One question, the audience. The contents come from the workspace.
- People go into an external view only when the user says so.
- Draft or Testing work goes public only when the user has seen the count and said so.
- One view per audience. Extend before creating.
- `update_shared_view` replaces the whole item list. Read first.
- Say "public to anyone with the link" every time.
