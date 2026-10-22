---
name: evaluate-the-stack
description: Answer "do we already have something that does this" from a Puzzle workspace through the Puzzle MCP, before a tool is bought, built or added. Reads three layers (the Tools canvas with costs and status, each tool's data model, the steps that use each tool and whether they're Live) and gives a verdict first: covered, partially covered, or gap, with the evidence. Flags two tools covering the same function, and tools that carry a cost but no Live step. Load when the user asks "do we have a tool for X", "does our stack already handle X", "are we paying for something we already have", "is there overlap between A and B", "should we add [tool]", or "audit our stack". Reads only; a decision that follows is logged with log-a-decision.
---

# Evaluate the stack

The question arrives as a tool name ("should we get Calendly?") or a need ("we need to schedule client calls"). Either way, the answer comes from the map: what tools exist, what records they hold, and which steps use them today. The map often shows the operation already pays for the capability, or that two tools do the same job, before anyone opens a vendor page.

Load `read-the-map` first.

## Phrase the need as a capability

A tool name becomes what it does: "Calendly" becomes "let someone outside the company book time on a calendar". A need stays a need. One capability per evaluation; "a CRM" is five capabilities and gets five rows.

## The three-layer read

1. **Catalog.** `list_tools` scope `workspace` with `include: ["status", "cost_items", "tool_group_name", "notes"]`. Every tool, its status (Active, Considering, Cancelled), what it costs, which group it sits in. Page through.
2. **Data models.** `list_entities` with `include: ["tool_name", "account_tool_id", "attribute_count", "step_count"]`, and `list_attributes` with `include: ["entity_name", "tool_name", "step_count"]` for the entities near the capability. A tool that holds a Booking entity with a date, a duration and an attendee can probably do scheduling, whatever its name.
3. **Active steps.** `list_steps` with `tool_id` for each candidate tool and `include: ["status", "executor", "section_name", "type"]`. Live steps mean the tool is doing work today; zero Live steps with a cost item means the operation pays for something the map says nobody uses. Step types help: `meeting` and `form` steps on a tool say "booking"; `email` and `sequence` say "outreach".

Candidates come from all three layers: tools whose name or group suggests the capability, tools whose entities suggest it, tools whose steps suggest it. The notes on tools and steps are searched too (`list_steps` with `query`).

## The verdict, first

```
# Do we already have: <capability>
Verdict: COVERED by <tool> | PARTIALLY COVERED by <tool> (<what's missing>) | GAP

Evidence
- <Tool>: <status>, <cost/mo>, holds <entities>, used on <n> Live steps (<sections>)
- <Tool>: ...

Overlap
- <Tool A> and <Tool B> both <function>: <evidence>; <n> and <n> Live steps; <cost each>
Paid but unused
- <Tool>: <cost/mo>, 0 Live steps, status Active

If you add <proposed tool>
- Replaces: <nothing | tool X on n steps>
- Duplicates: <tool Y's function on n steps>
- Would need: <entities/attributes, integrations> (to verify against the vendor)

Recommendation: <one line>. Log it? (log-a-decision)
```

Rules for the verdict:

- **Covered** means a tool in the workspace holds the records and has Live steps doing the thing, or could with configuration the user confirms.
- **Partially covered** names what's missing (a record, a field, an integration, a step that's still manual) and whether the missing part is configuration or a different product.
- **Gap** means no tool, no record and no step touches the capability. Say so plainly; don't manufacture a stretch fit.
- Overlap is flagged whenever two tools share a group and an entity shape, or carry steps of the same type in the same sections. It's a flag, not a verdict; the user knows why they have two.

## Full stack audit

When the user asks for the whole stack: every tool through the three layers, grouped by function (from tool groups when they exist, otherwise from entities and step types), with per tool: status, monthly cost from cost items, entities held, Live steps, Draft steps. Then the lists: overlaps, paid-but-unused, used-but-uncosted (Live steps, no cost item), Considering tools with Live steps (adopted without the status changing). The output is a table per function and the four lists. `cost-a-process` prices anything that needs a figure.

## After the verdict

- A decision (add, drop, consolidate, keep) goes to the changelog through `log-a-decision`, status idea or planned, linked to the tools involved.
- A drop or a replacement goes through `change-impact` before anyone acts on it.
- A Considering tool that is in fact in use gets its status fixed through `map-tools-and-data`, after approval.

## Rules

- Verdict first, evidence second, recommendation last.
- Evidence is the map: tools, entities, steps, costs, by name. No vendor comparisons from memory; anything about a proposed tool's abilities is "to verify".
- Live steps are what count as "in use". Documented is not the same as used, and the verdict says which it found.
- Costs come from cost items as entered; a tool with no cost item is "uncosted", not free.
- Reading is free. Nothing in this skill writes.
