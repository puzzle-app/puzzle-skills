---
name: map-tools-and-data
description: Build or extend the Tools canvas and the data model of a Puzzle workspace through the Puzzle MCP: the tools the operation runs on with their costs and status, tool groups, the entities and attributes each tool holds, and the links from attributes to the steps that read or write them; hands bulk asset discovery to map-tool-assets. Load when the user asks to "map our tools", "add our tech stack", "add tool costs", "set up the data model", "which fields does this step touch", "map our templates and reports", "add our Zaps and automations", or when a process build names a tool, record or field that doesn't exist yet. One intake round, propose before writing, link to steps, changelog at the end.
---

# Map tools and data

A step that names its tool, the record it touches and the fields it reads or writes is concrete. A tool that carries its cost and the steps that use it can be priced and replaced. This skill builds that layer: the Tools canvas, the data model, the assets inside tools, and the links from all of it to the workflow.

Load `read-the-map` first. The `tool_id` versus `account_tool_id` distinction matters on every call here.

## Three things the Tools canvas holds

- **Tools**: systems from Puzzle's catalogue added to the workspace, with status (Active, Considering, Cancelled), notes, and cost items (per seat, flat, usage, one time). Grouped into tool groups (Marketing, Finance, Delivery) or standalone.
- **Entities and attributes**: the records a tool holds (Contact, Deal, Ticket, Invoice) and their fields, each with a type. Attributes link to steps as trigger, input or output.
- **Assets**: the named things inside a tool with a URL: a board, a list, a dashboard, a template, a form, a document, a video, an automation, a sequence, a skill. Assets link to the steps that use them.

## Read before you write

1. `list_tabs` with canvas `tools`.
2. `list_tool_groups` with `include: ["tools.tool_id", "tools.account_tool_id", "tools.tool_name"]`.
3. `list_tools` scope `workspace` with `include: ["status", "cost_items", "tool_group_name", "notes"]`. Then scope `catalogue` with a comma-separated query for every tool the user named that isn't in the workspace yet.
4. `list_entities` with `include: ["tool_name", "account_tool_id", "attributes.id", "attributes.name", "attributes.field_type"]`.
5. `list_assets` with `include: ["tool_name", "account_tool_id", "type", "status", "asset_url", "step_count"]`.
6. The steps in scope: `list_steps` with `include: ["type", "executor", "notes", "tools.tool_id", "tools.tool_name"]`, so attributes and assets can be matched to the steps that use them.

Existing objects get extended or updated, never recreated.

## The single intake round

Draft everything from the user's material (a tool list, a subscription export, a process description, screenshots of a CRM, a connected tool you can enumerate), then ask once:

- **Tools**: which systems, grouped how. For each tool not in the catalogue, say so; the user can pick the closest catalogue entry or ask Puzzle to add it.
- **Status and cost**: Active, Considering or Cancelled; the charges (seats × price per month, a flat fee, usage, a one-time fee) and renewal dates where known. Offer the public list price as a starting point, marked as such.
- **Entities and attributes**: per tool, the records the mapped steps touch and the fields on each. Propose a sensible set per record (a Contact has name, email, phone, company, owner, stage) with field types from the allowed list, and let the user cut it down. Only model fields a step reads or writes.
- **Assets**: the few templates, boards or reports the user names, each with its URL. For a full pass through connected tools, point them at `map-tool-assets` after this build.
- **Step links**: which steps use which attribute (and whether as trigger, input or output) and which asset. Match on the step's notes and name first; judgment calls are listed separately.

Propose in chat, grouped by tool, and stop for approval:

```
## <Tool> (<in workspace | add from catalogue id N | not in catalogue>)
Group: <group> · Status: Active · Cost: 5 seats × $29/mo (list price, confirm) · Renews: 2027-03-01
Entities: Contact (email, phone, stage, owner), Deal (amount, close date, stage)
Assets: "Pipeline board" (Database, <url>), "Onboarding email sequence" (Sequence, <url>)
Step links: Contact.stage → "Update deal stage" (output); Pipeline board → 4 steps
Judgment calls: ...
Need from you: ...
```

## Build

1. **Tools and groups.** `create_tool_structure` with `tool_groups` (new groups with nested `tools` by catalogue `tool_id`, or `tool_group_id` to add to an existing group) and `standalone_tools`. Status and notes go on each tool. Capture the returned `account_tool_id`s, or read them back with `list_tools` scope `workspace`.
2. **Costs and status on existing tools.** `update_account_tools` with `cost_items`. The array replaces the tool's whole set: read the current set with `include: ["cost_items"]` first and pass back every row you want to keep, with its `id`. Move a tool into a group with `tool_group_id`.
3. **Entities and attributes.** `create_data_model` with `account_tool_id` (or `tool_id` for a catalogue tool not yet in the workspace) and `entities`, each with nested `attributes` (`name`, `field_type`, `api_name`, `description`). Fields for an existing entity go in `standalone_attributes` with `entity_id`. Capture attribute ids.
4. **Assets.** A handful of assets the user names go in here: `create_assets` with `account_tool_id` (or `tool_id`), `name`, `type`, `url`, `description`, `status`, and `step_ids`. For anything more, and for discovering what lives inside connected tools, run `map-tool-assets`; it owns the type mapping, the connector crawl and the matching to steps.
5. **Link attributes to steps.** `link_to_steps` with type attribute, `attribute_id`, `step_id`, and `kind` (trigger, input, output). Re-linking an attribute already on a step updates its kind.
6. **Link tools to steps** that name them but aren't linked: `link_to_steps` with type tool and the catalogue `tool_id`. The first tool linked becomes the step's primary tool.

## Verify

- `list_tools` scope `workspace` with `include: ["cost_items", "status", "tool_group_name"]`: every tool, cost and group as proposed.
- `list_entities` with `include: ["attribute_count"]` and `list_attributes` with `include: ["steps.step_name", "steps.kind"]`: every attribute exists and links where the proposal said.
- `list_assets` with `include: ["step_count", "status"]`: counts match; spot-check the heaviest-linked asset and any constructed URL.
- `list_steps` with `tool_id` for each new tool: the steps that name it are linked.

## Log it

A changelog entry with `log-a-decision`: tools added or changed with costs and status, entities and attributes created, assets created with counts by type, the step links made, judgment calls, and what was left out and why. Associate every tool touched by `account_tool_id`.

## Rules

- Propose, then write. No tool, record, field or asset is created before the user approves the list.
- Extend, never duplicate. Check the workspace and the catalogue before adding anything.
- Only model data the mapped steps depend on. A fifty-field Contact nobody's steps touch is noise.
- Never invent a cost or a URL. List prices are marked as list prices; constructed URLs are marked unverified until someone clicks one.
- Don't rewrite step notes to match an asset. Record the mismatch in the asset's description.
- `cost_items` replaces the whole set. Read before you write, or you delete costs.
- Catalogue `tool_id` for linking steps and creating tools; workspace `account_tool_id` for data, assets, people and the changelog.
