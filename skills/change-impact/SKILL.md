---
name: change-impact
description: Answer "what breaks if we change this" from a Puzzle workspace through the Puzzle MCP. A tool replaced or removed, a role removed or merged, a record or field retired: read every step, attribute, asset, person and shared view that depends on it, tier the impact (breaks, needs update, low risk), and when a replacement is named, list its capability gaps and the switch sequence. Load when the user asks "what breaks if we switch X for Y", "what's affected if we remove [tool]", "which processes use [role]", "impact of replacing X", "what touches [tool]", "can we drop [tool]", or before any change to the stack or the org. Reads only; offers to log the decision and to apply the relinking after approval.
---

# Change impact

Every process runs on systems, and every system change is a process change. The map exists so that question can be answered before the change, not after. This skill reads everything that depends on the thing being changed, tiers it, and, when a replacement is named, says what the replacement can't do yet and in what order to switch.

Load `read-the-map` first. The `tool_id` versus `account_tool_id` distinction matters on every call.

## What can be changed

- **A tool**, replaced or removed.
- **A role**, removed, merged, or renamed.
- **A record or field** (an entity or attribute), retired or moved to another tool.
- **A step or section**, removed. (Rarer; the same read applies to its connections and go-to targets.)

## Read the dependents

For a tool:

1. `list_tools` scope `workspace` with `query` for its `id` (catalogue) and `account_tool_id`, plus `include: ["cost_items", "status", "tool_group_name"]`.
2. Steps: `list_steps` with `tool_id` and `include: ["section_name", "status", "executor", "primary_tool_id", "tools.tool_id", "tools.tool_name", "notes", "roles.role_name"]`. Page through. Exclude Archived.
3. Data: `list_entities` with `account_tool_id` and `include: ["attribute_count", "step_count"]`; `list_attributes` with `account_tool_id` and `include: ["steps.step_id", "steps.kind", "entity_name"]`.
4. Assets: `list_assets` with `account_tool_id` and `include: ["type", "status", "step_count", "steps.step_name"]`.
5. People with access: `list_people` with `account_tool_id`.
6. Shared views: `list_shared_views` with `include: ["items.type", "items.id", "items.name"]`; any view holding a section that contains a dependent step is affected.
7. Decisions: `list_changelog_entries` with `include: ["associated_tools.account_tool_id", "status"]` for anything in progress that touches the tool.

For a role: `list_roles` for its id; `list_steps` with `role_id` and `include: ["section_name", "status", "executor", "roles.role_name", "roles.involvement"]`; the people in it (`list_roles` with `include: ["people.person_id", "people.first", "people.last"]`); its reporting lines (`list_teams` with `role_connections.*`).

For an entity or attribute: `list_attributes` with `entity_id` or `id` and `include: ["steps.step_id", "steps.step_name", "steps.kind", "tool_name"]`.

## Tier the impact

| Tier | A step is here when | For data, assets, people |
|---|---|---|
| **Breaks** | the tool is its only tool, or its primary tool with no alternative on the step; the role is its only responsible role; the attribute is its only input or trigger | an attribute with no equivalent anywhere else; an asset with no replacement; a person whose only access to a process is through this tool |
| **Needs update** | the step uses the tool alongside another, or its note names the tool, or the role is approver/consulted/informed | an attribute that also exists in another tool; an asset that can be re-pointed; a shared view that will show a changed section |
| **Low risk** | the step is Draft or Testing, or the tool is one of several on an Automation step with a stated fallback | data or assets already marked Deprecated |

Architecture-only sections (a catalogue of a tool's own setup) are listed separately; they describe the tool rather than depend on it.

## When a replacement is named

1. **Capability gaps.** For every attribute in the old tool that a step reads or writes, say whether the replacement holds it: from the replacement's live schema through a connector if present, from its data model on the Tools canvas if it's already in the workspace, otherwise "to verify". Same for each asset type (does the replacement have boards, sequences, forms). Never claim what the replacement can do without a source; "to verify" is the honest default.
2. **The switch sequence.** In this order, because each depends on the one before:
   1. The replacement on the Tools canvas, with status Considering, through `map-tools-and-data`.
   2. Its entities and attributes, so the step links have a target.
   3. Assets rebuilt or re-pointed in the replacement, through `map-tool-assets`.
   4. Each Breaks step re-linked (`link_to_steps` tool and attributes), then each Needs-update step, with notes rewritten where they name the old tool.
   5. Shared views checked; the old tool set to Cancelled, never deleted while a Draft step still names it.
   6. The changelog entry that records the switch, with the cost scenario if cost changes (`cost-a-process`).
3. **What the sequence does not cover**: migrating the data itself, retraining people, the vendor contract. Say so.

## Output

```
# Change impact: <replace X with Y | remove X | merge role A into B>
Read from the workspace on <date>. <n> steps across <n> sections, <n> attributes, <n> assets, <n> people, <n> shared views.

## Breaks (<n>)
| Step | Section | Why | Fix |
...
## Needs update (<n>)
...
## Low risk (<n>)
...
## Data and assets
<entities and attributes by tier; assets by tier>
## People and views
<people who lose access; shared views that change>

## Capability gaps in <Y>   (when a replacement is named)
| Needed | In Y? | Evidence |
...
## Switch sequence
1. ...
## Not covered here
- data migration · training · contract
```

Numbers in the headline come from a full page-through.

## After the read

- Offer to record it: `log-a-decision`, status idea (exploring) or planned (decided), linked to every dependent step and both tools.
- Offer to apply the relinking when the user decides to switch: the re-links, notes and status changes above, proposed as a push plan and pushed only on approval. Nothing in this skill writes on its own.

## Rules

- Every row names a step, attribute, asset, person or view by name and id. No "various processes".
- Tiers come from the links on the map, not from guesses about how important a step feels.
- A replacement's capabilities are "to verify" until a schema or the user says otherwise.
- Archived content is left out; Draft and Testing content is listed, as low risk, not hidden.
- Reading is free. The switch is a build, approved like any other.
