---
name: map-tool-assets
description: Pull the assets that live inside the tools on a Puzzle workspace's Tools canvas (boards, lists, dashboards, reports, templates, forms, documents, videos, web pages, help articles, automations, sequences, AI skills) out of the connected tools through their MCP connectors, propose them, create them as Puzzle assets with their URLs, and link each to the steps that run, read or embed it. Load when the user asks to "map our assets", "import our templates, boards, docs or videos", "what's in our tools that the map should point at", "link our Zaps and automations to steps", or after map-tools-and-data has inventoried the stack. Discovers through whatever connectors are present, pages through everything, matches assets to steps by URL and name, batches the creates, and keeps one running changelog entry per workspace.
---

# Map tool assets

A tool on the Tools canvas is a box until the map says what lives inside it: the board the team works from, the template every email starts from, the dashboard the manager reads, the Zap that moves the record, the video that trains the new hire. Puzzle calls those **assets**: a name, a type, the URL where it lives, and the steps that use it. This skill finds them in the tools you have connected, proposes them, creates them, and links them to the workflow.

The flow is always: **ask, discover, propose, build, link, verify, log.** Nothing is created before the user approves the proposal.

Load `read-the-map` first. The `tool_id` versus `account_tool_id` distinction matters on every call here.

## 1. Ask, one round

Ask once, together:

1. **Which workspace**, if more than one is connected. Never write to a workspace the user did not name.
2. **Which tools to pull assets from.** List the connectors in this session that can enumerate assets (a CRM's lists and views, a work-management tool's boards, an automation platform's workflows, a CMS's pages and collections, a drive's documents, a video platform's uploads, a help center's articles, a form builder's forms) and let the user pick. If they name a tool with no connector, say so and offer to work from pasted URLs or screenshots instead.
3. **Scope limits**, only if the tool is large: one workspace inside the tool, only live pages, only public videos, only automations that are switched on.

If the request already answered any of these, don't ask again.

## 2. Discover, read-only

For each chosen tool:

- **Find the Puzzle tool.** `list_tools` with scope `workspace` for its `account_tool_id`. If the tool isn't in the workspace yet, flag it in the proposal; `map-tools-and-data` adds it.
- **Check for existing assets.** `list_assets` with `account_tool_id` and `include: ["type", "status", "asset_url", "step_count"]`, so nothing is duplicated. An existing asset gets updated, not recreated.
- **Enumerate the tool through its connector.** Page through everything: follow cursors and offsets until the connector says there is no more. When a response is too large to read, save it to a file and parse it with a script (`python3 -I`) rather than reading it into context.
- **Hand big crawls to a subagent.** Hundreds of articles or thousands of items get a read-only brief and come back as a JSON inventory in a scratch folder.
- **Get the steps.** `list_steps` for the sections in scope with `include: ["notes", "section_name", "tools.tool_id", "tools.tool_name"]`, and match assets to steps by, in order of strength:
  1. the asset's URL or id appearing in the step's notes;
  2. the asset's name appearing in the step's name or notes;
  3. a step that clearly describes using that asset. These are judgment calls; list them separately in the proposal.
- **Exclude** Archived steps and steps that only send a message, post to chat, or wait.

### URLs

- Use the URL the connector returns. If you build one from an id and a known pattern, mark it **unverified** in the proposal and ask the user to click one to confirm.
- An asset with no reachable URL (private, or the connector can't see it) goes under **"Need a URL from you"**. Never guess a URL.
- Use the most direct link a person would open: the item page, not the folder; the public video, not the studio view.

## 3. Propose, and stop for approval

Present in chat, grouped by tool:

- **Assets to create**: name, type, status, URL (marked unverified if built), a one-line description.
- **Step links**: which steps each asset lands on. Call out the heaviest-linked assets and any section where one asset covers every step.
- **Judgment calls**: matches that weren't explicit in the notes.
- **No matching step**: assets that will exist but link to nothing.
- **Left out, and why**: archived only, broken links, duplicates, items a collection already covers, anything that looks like someone else's data.
- **Need from you**: missing URLs, ownership questions, scope calls.

End with one marker: `👉 I need from you: …` with the specific items, or `✅ Nothing needed from you, approve to build`. Create nothing until the user approves.

## 4. Build

`create_assets` in batches of about 60, each with `account_tool_id` (or `tool_id` for a catalogue tool not yet in the workspace), `name`, `type`, `url`, `description`, `status`, and `step_ids` to link on creation.

### Type mapping

| Thing in the tool | Asset type |
|---|---|
| Board, table, CRM object or view, sheet, CMS collection, list | Database (name a list "List: <name>", since List isn't a type) |
| Dashboard, report | Report |
| Automation, Zap, scenario, workflow in a tool | Workflow |
| Email sequence, drip, cadence | Sequence |
| AI skill, prompt, agent instruction | Skill |
| Video | Video |
| Web page, help article, CMS item page | Webpage |
| Doc, slide deck, file | Document |
| Form, survey | Form |
| Folder, profile, generic link | Link |

### Descriptions

Short and factual: what the asset is; how it's shared, if relevant (private, shareable, public); the owner, if it lives outside the user's own domain; any other name the step notes use for it ("Linked in step notes as: …"). Don't record folder locations unless asked.

### Status

Active if the asset is live or switched on. Deprecated if it is off, replaced, or titled as deprecated.

Capture the returned asset ids immediately.

## 5. Link

`link_to_steps` with `type: asset`, `asset_id` and `step_id`, from the approved step map, for any links not passed as `step_ids` at creation. Linking an asset already on a step is a no-op.

If an asset belongs on a map that has no step for it (an architecture or catalogue section), follow that section's existing step conventions: same type, status, executor, tool and note format. Only add steps when the user asks.

Don't edit step notes, even when they name an asset wrongly. Record the mismatch in the asset's description.

## 6. Verify

- `list_assets` per tool with `include: ["step_count", "status"]`: the count matches the proposal.
- Spot-check two to four assets with `include: ["steps.step_name"]`: the heaviest-linked one, one shared asset, one built URL.
- Report any URL still unverified so the user can click it.

## 7. Log

One running changelog entry per workspace for asset mapping.

- Find it: `list_changelog_entries` with `query: "assets"`.
- Extend its body with a section for each new tool, keeping every existing word. Associate the new tools with `update_changelog_entries` and `add_account_tool_ids`.
- Only create a new entry if none exists, through `log-a-decision`: owner from `list_people`, status completed.

Each tool section covers counts by type, step links, judgment calls, no-match assets, what was left out and why, and gaps found. Add a line to a "How the data was gathered" section naming the connector and the date.

## Reply format

- Lead with what was created and linked, by tool, in a few lines.
- Then judgment calls and gaps.
- End with exactly one marker: `👉 I need from you: …` or `✅ Nothing needed from you`.

## Rules

- Propose, then write. No asset exists before the user approves the list.
- Never invent a URL. Built URLs are marked until clicked; missing URLs are asked for.
- Extend, never duplicate. Existing assets get updated.
- Page through everything. A connector's first page is not the inventory.
- Someone else's data stays out. A client's items inside a shared tool, or anything the user did not scope, is listed under "left out".
- Catalogue `tool_id` creates and links; workspace `account_tool_id` filters assets, data and the changelog.
