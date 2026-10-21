---
name: cost-a-process
description: Compute what a process, a section, a tab or a whole Puzzle workspace costs per month from the map, through the Puzzle MCP: labor from each Person step's duration, frequency and responsible role's hourly rate, tool cost allocated across the steps that use each tool, and, when a future state exists, the net, hours returned and payback. Load when the user asks "what does this process cost", "how much time does this take", "cost of the current state", "what would we save", "ROI of this change", "business case", or wants a cost scenario for a changelog entry. Every figure traces to a step, a rate or a tool cost in the workspace; missing inputs are reported, never estimated.
---

# Cost a process

Puzzle turns a map into a costed operation when every manual step carries its duration and frequency and every role carries its hourly rate. This skill reads those inputs and computes the cost of a process today, the cost of a proposed or built future state, and the difference. One model, used for the current state and the future state alike, so a promised saving and a measured saving reconcile.

Load `read-the-map` first.

## The model

- **Labor cost per step per month** = duration (minutes) ÷ 60 × frequency (runs per month) × the responsible role's hourly rate. Only Person steps carry labor cost. A step with an approver, consulted or informed role carries labor only for the responsible role unless the user wants review time modeled, in which case ask for the reviewer's minutes.
- **Tool cost per step per month** = the tool's monthly cost allocated across every step linked to it, weighted by each step's duration × frequency. Label it "allocated share". A step with no duration or frequency gets no share and is listed as missing inputs. A tool linked to no steps is listed as unallocated.
- **Monthly cost of a cost item**: per_seat = amount × quantity ÷ period_months; flat = amount ÷ period_months; usage = amount per month as entered (state the rate reference); one_time is excluded from the monthly figure and reported separately.
- **Section cost per month** = the sum over its steps, labor and tools separately, then together.
- **Hours returned per month** = current state labor minutes minus future state labor minutes, ÷ 60.
- **Net per month** = current state cost minus future state cost, labor and tools separately, then together.
- **One-time costs** = build, migration, setup fees, from the user. **Payback (months)** = one-time costs ÷ net per month.

Automation and AI Agent steps carry no labor cost. Their tool cost (the automation platform, the model usage) is a tool cost item on that tool.

## Read

1. Scope: `list_tabs`, then `list_sections` for the tab(s) with `include: ["step_count"]`. Current state and future state usually live on separate tabs or in separate sections; confirm which is which with the user.
2. Steps: `list_steps` per section with `include: ["executor", "status", "duration", "frequency", "roles.role_id", "roles.role_name", "roles.involvement", "tools.tool_id", "tools.tool_name"]`. Page through all of them.
3. Rates: `list_roles` with `include: ["hourly_rate", "team_name"]`. The rate arrives as `{"amount", "currency"}` or `null`; a null rate is a missing input.
4. Tool costs: `list_tools` scope `workspace` with `include: ["cost_items", "status"]`.
5. Steps per tool, for allocation: from the step list already loaded, or `list_steps` with `tool_id` for each tool when the scope is the whole workspace.
6. Scenarios already recorded: `list_changelog_entries` with `include: ["body", "status", "associated_steps.step_id"]` for entries that carry a cost scenario; cite them rather than recomputing where they cover the same change.

## Procedure

1. For every Person step in scope, pull duration, frequency, responsible role and rate. List every step missing any of the four. Those are reported, not estimated.
2. Compute labor per step, per section, per tab.
3. Convert each tool's cost items to a monthly figure. Allocate across linked steps by weight. Report unallocated tools.
4. If a future state exists (a tab, a section, or a proposal from `find-automation-opportunities`), compute it the same way. Steps that became Automation or AI Agent carry no labor; add new tools at the cost the user gave or the quoted list price, marked as such.
5. Compute the net, hours returned, and payback from one-time costs the user supplies.
6. Write the report. Every figure cites the steps, the rates and the tool costs behind it.
7. Propose it in chat. Before any figure goes to someone else, the user confirms it.
8. Offer to record it: a changelog entry through `log-a-decision` with the cost table in the body (current, future, net), linked to the steps and tools, so the scenario lives on the entry.

## Output format

```
# Cost: <scope>, from the workspace on <date>
Rates: <from the Team canvas | n roles without a rate>. Figures in <currency> per month unless stated.

## Summary
| | Current state | Future state | Net per month |
|---|---|---|---|
| Labor | | | |
| Tools (allocated) | | | |
| Total | | | |
Hours of manual work per month: <n> now, <n> future, <n> returned.
One-time costs: <n>. Payback: <n> months.

## By section
### <Section>
| Step | Executor now → future | Role | Min × runs/mo | Rate | Labor now | Labor future |
|---|---|---|---|---|---|---|
Tools now: <tool: allocated share>. Tools future: <...>. Net: <n>.

## Steps missing cost inputs (not estimated)
- <section: step (id)>: missing <duration | frequency | responsible role | rate on role X>

## Tools not allocated
- <tool>: $<n>/mo, linked to no steps in scope

## Assumptions and sources
- Rate basis per role, list prices marked, one-time costs as given
```

## Rules

- Every number traces to a step, a rate, a cost item or a scenario in the workspace, or to a vendor price with a date. Where an input is missing, report the gap and ask; the `audit-the-map` skill finds them all at once.
- A future state figure is a projection until the work is live and re-measured. Say so.
- Labor at hourly rate is the cost of time, not the saving in cash. Hours returned count only if the role's time has somewhere to go; say that when the reader might assume otherwise.
- Keep the user's currency and their rate basis (base or loaded). Don't mix.
- The report is generated from the workspace each time. Never edit a number in the document without changing it in the map first.
