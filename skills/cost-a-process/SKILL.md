---
name: cost-a-process
description: 'Compute what a process, a section, a tab or a whole Puzzle workspace costs per month from the map, through the Puzzle MCP: labor from each Person step''s duration, frequency and responsible role''s hourly rate, tool cost allocated across the steps that use each tool, and, when a future state exists, the net, hours returned and payback, with actual tool spend and measured run frequency beside the model when logged. Load when the user asks "what does this process cost", "how much time does this take", "cost of the current state", "what would we save", "ROI of this change", "business case", or wants a cost scenario for a changelog entry. Every figure traces to a step, a rate or a tool cost in the workspace; missing inputs are reported, never estimated.'
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
6. Scenarios already recorded: `list_changelog_entries` with `include: ["body", "status", "associated_steps.step_id", "current_state", "future_state", "cost_analysis"]`. On the Optimizer plan an entry can name its current state and future state sections or tabs, and Puzzle rolls each side up: labor cost, tool cost, total and hours, monthly and annual, plus the net (future minus current; negative is a saving). An entry whose `has_current` and `has_future` are both true is the scenario of record for that change: cite it rather than recomputing. Older entries may carry a cost table in the body instead; cite those as they are.
7. Actual spend, when the workspace logs charges: `list_tool_charges` per tool in scope. `meta.spent_last_12_months` and `meta.currency` give the real annual spend; the rows give the months.
8. Measured inputs, when the workspace has Runs (`list_runs` is in the tool list): `list_runs` with `step_id` and `events: true` for the steps in scope, over the history the plan allows. Events per step per month are measured frequency. For runs, `last_event_at` minus `started_at` is the elapsed time of the whole run, not hands-on minutes.
9. Tags, when the user asks for cost by tag ("what do our weekly steps cost", "what does the onboarding program cost across teams"): `list_steps` with `tag_id`, with the same includes as step 2.

## Procedure

1. For every Person step in scope, pull duration, frequency, responsible role and rate. List every step missing any of the four. Those are reported, not estimated.
2. Compute labor per step, per section, per tab.
3. Convert each tool's cost items to a monthly figure. Allocate across linked steps by weight. Report unallocated tools.
4. If a future state exists (a tab, a section, or a proposal from `find-automation-opportunities`), compute it the same way. Steps that became Automation or AI Agent carry no labor; add new tools at the cost the user gave or the quoted list price, marked as such. When a changelog entry already carries both sides, lead with its cost analysis and use this model for what the roll-up does not show: the per-step table, the gaps, cost by tag or by role. If a side of the roll-up totals zero while it holds steps, its inputs are missing; list them. If the roll-up and this model disagree, report both and name the inputs that explain the difference; never adjust an input to make them match.
5. Actuals beside the model, when steps 7 and 8 found data:
   - **Tools.** Set each tool's actual monthly spend (12-month spend ÷ 12, or ÷ the months charged when under a year) beside its cost items' monthly figure. A gap over about 10% is a finding: either the plan is wrong or usage changed. Report it; never edit a cost item to make them match. The allocation still uses the cost items unless the user chooses actuals; say which basis the table uses.
   - **Frequency.** Set measured events per month beside each step's mapped frequency. Only steps someone logs against have a measured figure, and a step logged only by agents shows the agent's frequency, not the people's. Offer to update a mapped frequency only on the user's word, and recompute.
   - **Duration.** Runs measure elapsed time, which includes waiting. Never use it as a step's duration. Report it as cycle time beside the mapped total.
6. Compute the net, hours returned, and payback from one-time costs the user supplies.
7. Cost by tag, when asked: the same per-step labor and allocated tool figures, summed over the steps carrying the tag, across every section they sit in. A step carrying two of the tags compared counts under each, so the rows do not add up to the total; say so. Operational tags make the sharpest cuts: what the steps tagged Error-prone or Bottleneck cost each month is often the case for fixing them.
8. Write the report. Every figure cites the steps, the rates and the tool costs behind it.
9. Propose it in chat. Before any figure goes to someone else, the user confirms it.
10. Offer to record it: a changelog entry through `log-a-decision` with its current state and future state set to the sections or tabs costed here, and the steps that will not run excluded from the future side by status (or by tag for a scope cut), so Puzzle keeps the roll-up current as the map changes. The body carries the rationale, the assumptions and the gaps, not a copy of the totals. Where the plan has no state fields, put the cost table in the body as before.

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

## By tag (when asked)
| Tag | Steps | Sections | Labor | Tools (allocated) | Total |
|---|---|---|---|---|---|

## Actuals (when logged)
| Tool | Plan per month (cost items) | Actual per month (charges) | Variance | Charges, period |
|---|---|---|---|---|
| Step | Mapped runs/mo | Measured events/mo | Source (runs, n months) |
|---|---|---|---|
Cycle time per run: <median elapsed, n runs>. Elapsed time, not hands-on time.

## Steps missing cost inputs (not estimated)
- <section: step (id)>: missing <duration | frequency | responsible role | rate on role X>

## Tools not allocated
- <tool>: $<n>/mo, linked to no steps in scope

## Assumptions and sources
- Rate basis per role, list prices marked, one-time costs as given
```

## Rules

- Every number traces to a step, a rate, a cost item or a scenario in the workspace, or to a vendor price with a date. Where an input is missing, report the gap and ask; the `audit-the-map` skill finds them all at once.
- A future state figure is a projection until the work is live and re-measured. Say so, including when it comes from a changelog entry's cost analysis.
- Labor at hourly rate is the cost of time, not the saving in cash. Hours returned count only if the role's time has somewhere to go; say that when the reader might assume otherwise.
- Measured figures are labeled measured, with their source and period. Plan figures are labeled plan. Never blend the two in one cell.
- Keep the user's currency and their rate basis (base or loaded). Don't mix.
- The report is generated from the workspace each time. Never edit a number in the document without changing it in the map first.
