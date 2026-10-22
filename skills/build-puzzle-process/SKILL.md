---
name: build-puzzle-process
description: Build thorough processes in any Puzzle workspace via the Puzzle MCP. Load whenever the user asks to "build out this process", "map this in Puzzle", "document this workflow", "create a process for X", "turn this transcript into a map", "map how our [tool] is set up", or when a workflow needs to become a Puzzle section with steps, executors, roles, tools, conditionals, attributes and notes. Also load when editing or extending an existing Puzzle process. Covers one consolidated intake, as few sections as possible (10 to 25 steps each), conditional branches and go-to steps, orientation chosen by shape, a conditional trace, one right-to-left connector default with three exceptions, a handle table, a two-call handle pass, go-to steps for anything that would cross, a visual check of the built map, step typing and titling, RACI roles with hourly rates, costing inputs, attributes, tools, triggers, delay steps and a changelog entry. When in doubt building anything in Puzzle, use this skill.
---

# Build a Puzzle Process

This skill captures how to build an excellent, thorough Puzzle process. It uses every corner of the tool: the workflow canvas, the team canvas, the tools canvas and data model, step costing, and the changelog. Follow it in order.

Two rules govern everything else:

1. **Complete in one shot.** A process is not "built" until every step carries its full set of inputs (type, status, executor, roles, tools, attributes, cost, notes), every branch resolves somewhere, every connector has its handles set and reads cleanly, new roles and tools exist on their canvases, and the changelog records what happened. Never deliver a map the user has to come back and patch with "you forgot this, you forgot this."
2. **One intake round, ever.** Whatever the prompt doesn't tell you, collect in a single consolidated round of questions before building. Never drip-feed questions across multiple turns.

---

## The build order (do not skip steps)

1. **Orient before you touch anything.** Call `list_tabs` to confirm the tab ID. Then `list_sections` (with `tab_id` and `include: ['step_count']`) to check for an existing section so you don't duplicate or fragment. If editing an existing process, `list_steps` to capture current step IDs and connection IDs before changing anything.
2. **Resolve roles, tools, and data up front.** Roles come from `list_teams` with `include: ['roles.id', 'roles.name', 'roles.hourly_rate']`. Tools come from `list_tools` — query a single comma-separated string of every tool name at once (e.g. `"Attio, QuickBooks, Intercom, monday.com, Claude"`) rather than one call per tool. Check `list_entities` and `list_attributes` for the data objects the process touches. This is how you discover what's missing before you ask about it.
3. **Draft the full process privately.** Work through every step, branch, and input against the Completeness Checklist below. Every gap you find becomes an intake question.
4. **Run the single intake round.** One consolidated set of questions covering every missing input (see "The single intake round"). Do the research first (e.g. hourly rates, proposed attributes) so most questions are confirm/adjust rather than open-ended.
5. **Trace each conditional.** One line per diamond: which outcome continues on the row, which goes above, which goes below, which becomes a go-to (see "The conditional trace"). That line sets the `steps` array order and marks the few connections that are not the default. For three or more conditionals, or any branch that crosses another, also draw the grid sketch. The acceptance bar is **zero crossings and zero connectors passing through a step**; anything that would still cross becomes a `go_to` step.
6. **Propose the full process in chat.** Every step fully specified: name, type, status, executor, roles, tools, attributes, frequency, duration, and a one-line note — plus the orientation (with the reason), the branch wiring, the **conditional trace** (and the grid sketch when required), and the **handle table** (see "Connectors"): one row per connection with its rule (D, A, B, C, or go-to), label, source handle, and target handle. Let the user evaluate the structure and the layout before anything is written to Puzzle.
7. **Create missing canvas objects first.** New roles (with hourly rates) on the Team Canvas, new tools on the Tools Canvas, new entities/attributes in the data model. These must exist before the workflow build so IDs are available for linking.
8. **Build in one call.** Use `create_process` with the full `sections` (one, or the stage sections the proposal approved), `steps`, and `connections` arrays in a single call, wiring connections via `temp_id` references, with `label` set inline on every connection that needs one. Include `role_ids`, `tool_ids`, `duration`, `frequency`, `status`, `executor`, `type`, and `notes` directly on each step. Set `direction`. Capture the returned step IDs. (Connections in `create_process` carry only `from`, `to`, and `label` — handles come next.)
9. **Run the handle pass, two calls.** `list_steps` on the new section with `include: ["connections", "connections.connection_id", "connections.to_step_id", "connections.to_step_name", "connections.label"]` to capture every connection ID. Call one sets the default on **every** connection (`right → left` in LTR, `bottom → top` in TTB), no exceptions, in batches of 25. Call two sets only the rows the handle table marks A, B or C. Same turn as the build. A connection that misses call one keeps Puzzle's nearest-side default, and a map with nearest-side handles is not built.
10. **Look at the map.** Screenshot the section (built-in browser, then Claude in Chrome, then computer use on the desktop, then ask the user; see "The visual check") and trace every connector. Fix any crossing, pass-through, or hook via `update_workflow` or a go-to step, then screenshot again. The handle table is a prediction of the layout; the screenshot is the proof. If no screenshot is possible, the changelog entry says the layout is unverified.
11. **Link what create_process can't carry.** Attributes always link post-build via `link_to_steps` with `type: attribute`. Approver, consulted, and informed roles also link post-build via `link_to_steps` with `type: role` and the right `involvement` (the `role_ids` array in `create_process` covers responsible only). Verify roles and tools landed; patch any misses with `link_to_steps`.
12. **Verify.** Re-run `list_steps` with includes for roles, tools, attributes, duration, frequency, notes, and connections. Confirm every connection in the handle table received a successful update (the API does not read handles back, so your record of the pass is the verification). Fix any label or handle that reads wrong via `update_workflow`.
13. **Memorialize in the changelog.** Always, including the handle table and the result of the visual check. See "Changelog" below.
14. **Offer to share, in one line.** The closing message ends with an offer: a shared view with this section, the team that owns it and the tools it uses. It is an offer, not a question before the build. On a yes, `share-the-map` takes over.

---

## The Completeness Checklist — what "fully built out" means

Every one of these must be resolved from the prompt, from workspace lookups, or from the single intake round. There is no fourth option.

Per step:

- Name (verb-first, roughly four to eight words)
- Type (from the step type enum)
- Status (Draft / In_Progress / Testing / Live / Archived)
- Executor (Person / Automation / AI Agent)
- RACI roles: responsible on every Person step (with hourly rate known), plus approver / consulted / informed where they genuinely apply
- Tool(s) the step touches
- Attributes: the fields read or written in that tool at that step
- Cost inputs on manual steps: duration in minutes + frequency per month
- A mini-SOP note

Per process:

- As few sections as possible: one up to about 25 steps; beyond that, stages of 10 to 25 steps cut at natural seams, named as stages of one process, connected across the boundary
- When the source is a transcript or a document: stated and inferred steps kept apart, and the inferred ones confirmed in the intake round
- Trigger known (ask if not stated) — the first step of the map is what kicks the process off
- Orientation chosen by shape (LTR timeline / TTB pipeline / LTR hybrid with drops) and stated with a reason
- Named people mapped to roles (ask if a person's role is unknown)
- Explicit waits modeled as delay steps (and only explicit ones)
- Every conditional branch resolves somewhere (loop back, diverge, or converge)
- Loop-backs longer than one step modeled as `go_to` steps, not connectors
- Every conditional traced (continue, above, below, go-to); grid sketched when there are three or more conditionals or any branch crosses another
- Every connection in the handle table with its rule (D by default; A, B, C or go-to by exception) and its handle pair before building
- Every post-conditional connector labeled
- No row wrapping and no manual-layout instructions to the user
- Handle pass executed as two `update_workflow` calls (the default on every connection ID, then the exceptions), recorded by ID
- Visual check done: screenshot taken, every connector traced, fixes applied; or the changelog says the layout is unverified
- Changelog entry written

---

## The single intake round

After orienting and drafting, gather **everything** missing in one consolidated round — a single message (or one structured multiple-choice prompt if your platform supports it), grouped so it's fast to answer:

- **Trigger** — what kicks this process off? Always ask if unstated. The answer becomes the first step of the map: a form submission, an inbound email, a calendar date, a signed contract, a threshold being crossed. A process whose first step is mid-action ("Review the request") with no visible trigger is incomplete.
- **Orientation** — horizontal (left to right) or vertical (top to bottom)? Always ask if the user didn't specify, but lead with a recommendation phrased as "this shape, because …" (see "Orientation").
- **Missing step facts** — executor, tool, role, or status for any step where the prompt didn't say.
- **Costing** — duration and monthly frequency for each manual step that lacks them. Offer researched estimates to confirm rather than asking cold.
- **New roles** — for any role mentioned that isn't on the Team Canvas: present the role name and a researched average hourly rate for confirmation before creating it.
- **RACI** — present the inferred approver / consulted / informed assignments (from hierarchy and surrounding-step ownership) as a compact table for confirmation, alongside the responsible roles.
- **People** — for any actual person named in the prompt ("then Sarah reviews it"): ask what role that person holds if it isn't stated and can't be resolved from the People Canvas. Steps are owned by roles, so every named person must map to a role.
- **Attributes** — for steps whose tools have no matching entities/attributes: present a proposed entity + attribute list per step for approval before adding to the data model.
- **Branch logic** — any fork where the prompt is ambiguous about whether the paths rejoin, loop back, or diverge for good.

Do the legwork before asking: research rates, draft the attribute model, estimate durations. The intake should read as "confirm or correct this," not "tell me everything." One round. If an answer creates one genuinely unforeseeable follow-up, fold it into the proposal review rather than opening a second interrogation.

---

## As few sections as possible

A section is a stage of a process the eye can take in at once. The proxy is **10 to 25 steps per section**.

- A process of up to about 25 steps is **one section**. Do not split it. Left unattended, AI builders get "section-happy" and fragment one process into several, which breaks the visual story and the costing rollup.
- A process beyond that splits at its natural seams, each section 10 to 25 steps: a handoff between teams, a gate or sign-off, a change of owner, a wait of days. Name the sections as stages of one process ("Provider onboarding: Stage 2, First meeting") so they read as a sequence. A conditional and all its outcomes stay in one section; never cut a fork across a boundary.
- Connect the stages: the last step of one section connects to the first step of the next with the default handle pair, so the flow reads across the boundary.
- A section under 10 steps exists only when the whole process is that short.
- The split is part of the proposal in chat, with the seam named for each cut. The user approves it before anything is built.

## When the source is a transcript, notes, or a document

A call transcript, meeting notes, an old SOP, a screen recording's transcript, a long thread. The skill runs the same way, with one extra discipline: keep what the source says apart from what you inferred.

1. **Extract, don't invent.** Pull every trigger, step, owner, tool, decision, wait, exception and number the source states, noting the speaker where it helps. A step the source describes is *stated*. A step you added so the flow connects is *inferred*, and the draft marks it so.
2. **Resolve what the source leaves open** in the single intake round: the trigger; which outcome of each decision is the normal one; who owns a step, as a role rather than the speaker's name; the tool when someone says "the system"; durations and frequencies; whether a mentioned wait is routine. The round reads as "here is what I heard, confirm or correct", with the inferred items flagged.
3. **Ask the three things a transcript never says.** What happens before the part they described (the trigger). What happens when it goes wrong (the exceptions). What has changed since the conversation (the status). If the conversation hasn't happened yet, `interview-for-a-process` prepares it.
4. **Propose before building, as always**, with stated and inferred steps shown distinctly. The user's approval is what turns an inferred step into a stated one.
5. **Name the source in the changelog entry**: the call and its date, or the document, and which steps were inferred and then confirmed, so a later reader knows where each step came from.

## When the source is a tool's configuration

"Map how our HubSpot is set up", "diagram our ClickUp", "document our Zapier". The process already exists, inside a system, as stages, statuses, views and automations. Read it through the tool's connector (or screenshots and exports when there is none) and build it as a section on the Workflow canvas, so the tool's own flow sits on the same map as the people around it.

- **Pipelines and stages become steps.** A pipeline, board or status flow is the spine: one step per stage, named with the stage's own name ("Move deal to Contract Sent"), executor Person unless the tool moves it, the tool as the step's tool, the stage's fields as attributes.
- **Automations become Automation steps.** Each workflow, Zap, sequence or trigger in the tool is a step hung under the stage that fires it (exception A), named "Trigger: <what fires it>" then what it does, executor Automation, with the automation itself linked as an asset (`map-tool-assets`) so the step points at the real thing.
- **Views, forms and templates are assets, not steps.** Link them to the steps that use them.
- **Conditions in the tool are conditionals on the map.** A workflow branch ("if deal amount over 10k") is a `conditional` step with labeled outcomes, same grammar as any other.
- **What to read, by kind of tool.** A CRM: pipelines, stages, properties, workflows, sequences. A work-management tool: boards, groups or lists, status columns, automations, forms. An automation platform: each workflow's trigger, steps and the apps it touches; the map step is one per workflow, not one per action inside it, unless the user wants the inside mapped. An email marketing tool: lists, sequences, triggers.
- **The section's note** carries the tool, the date read, and what was left out (inactive automations, archived pipelines), so the map says what it reflects.
- **This is one process per pipeline.** A tool with three pipelines is three sections, or one section per pipeline inside the as-few-sections rule.

Everything else is unchanged: one intake round for what the configuration doesn't say (who does each stage, how long, how often), the proposal with the push plan, the handle pass, the changelog entry naming the tool as the source.

---

## Orientation — choose the shape, then build the graph for it

### What you actually control

Puzzle positions steps with a **Graphviz auto-layout computed from the connection graph and `direction`**. There is no x/y, no row, no column field anywhere in the API. The builder shapes the layout through exactly four levers: (a) `direction` on `create_process`, (b) which connections exist and which step each one points to, (c) the order steps are listed in the `steps` array, and (d) handles set on each connection **after** the build. Whatever Graphviz places is what ships; the job is to shape the graph and the handles so that result reads well. The API cannot wrap a long row onto a second line and cannot pin a branch above versus below the main line — so this skill never attempts either, and never hands the user manual-layout instructions ("drag this under that").

### Vocabulary

- **Spine** — the main path of the process: the row (LTR) or column (TTB) the eye follows first.
- **Continue branch / exit branch** — of a conditional, the outcome that keeps the spine going versus the outcome that leaves it.
- **Sub-row / side column** — a branch with two or more steps of its own before it rejoins or ends.
- **Skip branch** — an exit branch with no steps of its own that lands on a later spine step.
- **Fan-out** — one step feeding several *parallel* next steps (all of them happen). Not a conditional.
- **Fork** — a conditional splitting into *exclusive* outcomes (one of them happens).
- **Drop** — Automation / AI Agent steps hung below the step that triggers them.
- **Rejoin** — a branch's tail entering a spine step.
- **Handle grammar** — the source handle is the side the arrow *leaves*; the target handle is the side it *arrives*. The router draws orthogonal lines between them. Puzzle's own default picks the nearest side, which is what produces hooks and lines out of a diamond's bottom; this skill overrides it on every connection.
- **Flow-facing side** — the side of a step that faces the direction of flow: **right** in LTR, **bottom** in TTB. Its opposite is the **entry side**: left in LTR, top in TTB.
- **Lane** — an empty corridor a deep connector travels in: in TTB, a vertical corridor between columns or along the outer left/right edge of the section; in LTR, a horizontal corridor above or below a row. Lanes are what keep long connectors from cutting through steps.
- **Merge** — two or more connectors headed to the same target sharing one lane and one target handle, so they read as one line instead of crossing.

### Choosing the orientation

If the user hasn't said, ask in the intake round — but recommend, and state the recommendation as "this shape, because …":

- **left_to_right** when the map reads as a timeline of mostly Person steps with a handful of conditionals, where role and time badges matter. The default for any process where a reader should see "who does what, in order."
- **top_to_bottom** when the process is a pipeline of Automation / AI Agent steps with a conditional every two or three steps, branches that reconverge within a row or two, and terminators like "Skip — no match." Vertical reads like a flowchart and keeps each fork's outcomes side by side. Also prefer it for a long, mostly linear spine (roughly twelve or more spine steps): since the skill never wraps rows, a long LTR spine becomes one endless row, whereas a long column scrolls naturally.
- **Hybrid** is not a third `direction` value; it is LTR with drops. Choose it whenever a Person-driven spine triggers automations.

Set it on `create_process` via `direction`.

### Connector principles — one default, three exceptions

Puzzle sets a handle on every connection by nearest side. Nearest side is what produces hooks, outcomes leaving a diamond's bottom, and arrows wandering through the middle of a map. This skill overrides it on every connection, with one default and three exceptions, applied without case-by-case judgment.

1. **One default.** Every connection leaves the flow-facing side and enters the entry side: `right → left` in a left-to-right map, `bottom → top` in a top-to-bottom map. Spine connections, every outcome of a conditional, fan-outs, rejoins, short skips. The layout engine stacks the targets and the router splits the line; the handles stay the same.
2. **Three exceptions, nothing else.** A: automation drop. B: one-step loop-back. C: arc past other steps. Each is defined in the grammar below. A connection that is not one of those three gets the default.
3. **Go-to for anything that would still cross.** A connection that would cross a step or another connector after the default and the exceptions becomes a `go_to` step (see "Go-to steps"). Loop-backs longer than one step, a shared target reached from more than one row, a jump across a sub-row: all go-to. A go-to box reads; a crossing arrow does not.
4. **Conditionals have structure, not special handles.** At most three outcomes, all labeled. The continuing outcome keeps the spine row, a branch with its own steps goes above, a terminator or a skip goes below, and the order of the `steps` array is what puts them there. The diamond shape and the labels already say "exclusive fork"; the handles do not need to.
5. **Fan-outs are the same shape.** One step feeding N steps that all happen uses the default on every connection. Step type and labels carry the difference, not handles.

### The conditional trace

You can't see the canvas while planning, so decide each fork on paper. Before the handle table, write one line per conditional:

```
<Diamond>: continue = <outcome> → <target on the row> · above = <outcome> → <branch or target> · below = <outcome> → <terminator or skip> · go-to = <outcome> → Go to: <target> (why)
```

That line sets the `steps` array order after the diamond and marks which rows of the handle table are exceptions or go-tos. For a map with three or more conditionals, or any branch that crosses another, also draw the grid sketch: one cell per step, rows in the direction of flow, every connector traced. Example (TTB):

```
        [Trigger]
            |
        [Extract]
            |
       <Has URL?> ───────────────┐ (no)
     yes|                        |
   [Find by URL]          <Has name+domain?> ───────┐ (no → outer-right lane)
        |                  yes|                     |
        |            [Find by name]                 |
        └──────┬──────────────┘                     |
          <Found phone?>                            |
         ...                                        v
                                              <Has work email?>
```

Two lines that cross, or a line through a step, mean a different `steps` order, an exception C arc, or a go-to. Only propose the handle table once the trace is clean. The trace is a prediction of what Graphviz does; the visual check after the build confirms it.

### Left-to-right grammar

- **D. Default.** `right → left`. Every spine connection, every outcome of a conditional (two or three), every fan-out branch, every rejoin into the spine, every short skip to the next step on the row. The continuing outcome keeps the row; the others stack above and below; each branch then runs `right → left` as its own mini-row and rejoins the spine `right → left` at the first spine step past the fork. If a connection is not A, B or C, it is D.
- **A. Automation drop.** Automation / AI Agent steps triggered by a spine step hang below it: `bottom → top` from the trigger to the first automation and `bottom → top` down the chain. If the chain feeds back into the spine, its last step enters the next spine step `right → left` (D). If the space below is taken by a branch row, the drop goes above: `top → bottom` into the automation, and it re-enters the spine `right → left`.
- **B. One-step loop-back.** A step returning to the step immediately before it: `top → top`, arcing over the pair. Any loop-back longer than one step is a go-to step, not a connector.
- **C. Arc past other steps.** A forward connection whose target is two or more ranks away on a different row, with steps on the direct line between them: `top → top` over the map, or `bottom → bottom` under it when the space above is taken. Several arcs to one target share the same side and the same target handle. An arc that would still cross something is a go-to.
- **Go-to.** Everything else that would cross. Loop-backs longer than one step. A shared target (a terminator, a common rejoin) reached from conditionals on different rows: only the nearest row connects directly, every other row gets a go-to. A branch that would cut through a sub-row. Built per "Go-to steps".
- **Structure, set by the `steps` array.** List the spine in order. After each diamond, list the continuing outcome's target first (it stays on the row), then the branch with its own steps (above), then the terminator or skip target (below). List shared terminators last so they land at the edge of the map.
- **Outcomes.** At most three per conditional. A fourth means two conditionals, or a top-to-bottom map.
- **Labels.** Every connection leaving a conditional carries a label of one to three words; the house style prefixes them with ✅ / ❌ / ➕ where it helps ("✅Yes", "❌No", "➕New", "✅Existing"). Longer labels only when they carry the routing logic itself ("Stalled (25+ L14D)"). Spine connections in a timed sequence carry timing labels ("Day 0", "+5 days", "cohort close"). Branch labels sit on the horizontal run of the connector, so word them to read there.
- **No wrapping — ever.** The spine is one row, however long. A spine too long for one row is a reason to go top-to-bottom, never to wrap it and never to ask the user to drag steps.
- **Never in LTR.** Never enter a step from its right. Never leave a diamond from its top or bottom. Never send one outcome out the right and another out the bottom. Never draw a backward connector longer than one step. Never let two lines into one target arrive from different sides. Never let a connector cross another connector or run through a step.

### Top-to-bottom grammar

Same shape as LTR: one default (`bottom → top`), the same three exceptions in vertical terms (a side detour with its own steps, a one-step loop-back, a side lane past other steps), and a go-to for anything that would still cross. The T-rules below are the detail.

- **T1. Spine.** Single centre column, every spine connection `bottom → top`.
- **T2. Conditional — all outcomes leave bottom.** Every outcome whose target is on the next row leaves the **bottom** handle and enters the **top** of its target. Outcomes sit in columns: the continuing/most-common outcome under the diamond, the others to the left and right. Two outcomes → left and right (or centre and one side); three → left, centre, right. Labels sit on the horizontal run. Side handles are **not** used for adjacent outcomes — only for same-row peers (T6) and deep bypasses (T9).
- **T3. Converge.** A side-column branch rejoins in whichever way doesn't cross anything:
  - **From above** (the rejoin step is on a lower row than the branch's last step): `bottom → top`, merging into the rejoin step's top alongside any other line arriving there. This is the common case.
  - **Same row** (the branch's last step sits beside the rejoin step): horizontally — from the left column `right → left`, from the right column `left → right`.
  - **From a lane** (the branch arrives via a deep bypass lane running beside the target): into the side that faces the lane.
- **T4. Side detour with its own steps.** A branch of two or more steps runs down its own side column `bottom → top`, parallel to the spine, and rejoins per T3.
- **T5. Terminators.** "Skip — …" / "End — …" steps live in a side column and dead-end there with no outgoing connection. Keep them off the spine column so the spine reads as the happy path.
- **T6. Exception off a non-conditional step.** An exception that fires from an ordinary step leaves that step's side and enters the **opposite side** of a peer step on the same row: `left → right` or `right → left`, labeled with the exception condition ("on batch run failure").
- **T7. Labels.** Same rule as the LTR Labels rule; lowercase, terse labels are the house style in TTB ("matched", "no match", "has domain", "no domain", "hit", "miss").
- **T8. Never in TTB.** Never use `left`/`right` for an adjacent spine connection. Never use `top`/`bottom` for a same-row converge. Never enter a step from its bottom. Never let a connector cross another connector or run through a step.
- **T9. Deep bypass — side exit into a lane.** When a conditional outcome's target is several rows down or in a far column (so a `bottom → top` line would cut through the steps in between), leave the diamond from the **side facing the target's column** (`right` or `left`), run horizontally to an open lane, travel down the lane, and enter the target's **top** if the lane lands above it, or the target's **facing side** if the lane runs beside it. Use outer lanes (the section's far edge) for the deepest jumps. Multiple deep outcomes headed to the same target (e.g. several "no" branches into one "Return: no phone found" terminator) merge into one lane and one target handle. The normal pairing on a busy TTB diamond is: adjacent outcome out the bottom, deep outcome out the side.
- **T10. LTR's top → top in TTB terms.** The TTB equivalent of the LTR arc is a side lane: to get past a run of downstream steps without cutting through them, go out the side, down the lane, and back in. Never draw a long `bottom → top` line down the middle of a column that other steps occupy.

### Shaping the graph so Graphviz cooperates

Placement comes from the graph, so build the graph deliberately:

- List steps in the `steps` array in spine order first. After each diamond: the continuing outcome's target, then the branch with its own steps, then the terminator or skip target. Then any remaining sub-rows / side columns, then shared terminators last. Graphviz ranks by connection but breaks ties by order, and this order is what puts the continuing outcome on the row, the branch above and the terminator below.
- Give every branch a real target. A dangling branch collapses the layout.
- Keep the spine a single path: avoid two connections into the same spine step from the same side unless they are converging by design (a rejoin in LTR, T3 in TTB).
- Order steps so deep targets land at the edges: list a shared terminator (e.g. "Return: no phone found") last so Graphviz pushes it to the bottom/right, where outer lanes can reach it without crossing the middle of the map.
- Never add "helper" connections to force a shape — every connection must be a real handoff. If a shape can't be reached with real connections plus handles, it isn't a shape this skill produces; pick the orientation that reads best with the real graph and move on.
- For hybrids, connect the drop from the *triggering* step, not from the step after it, or Graphviz pulls the automation into the spine.

---

## Conditionals — every branch must land somewhere

Wherever the process forks, model it as a **conditional step** (type `conditional`), named as the question it answers: "Did eligibility pass?", "Is the invoice correct?". Then identify which of the three branch patterns applies — this is the single most common thing sloppy builds get wrong:

1. **Loop-back (the rework path).** One branch is a fix/follow-up that returns to earlier work — e.g. "Not approved → revise and resubmit." The follow-up step's outgoing connection goes **back to the step before the conditional** (or whichever earlier step gets redone). No dangling arrows, no dead-end "fix it" boxes. Distance rule: a connector is only right when the target is **the step immediately before** (exception B, `top → top`); any farther and it becomes a `go_to` step instead (see "Go-to steps").
2. **Full divergence.** The two paths genuinely never recombine — each branch gets its own sequence of steps through to its own end. Terminal branches get a real terminator step (no role or tool; it just ends the flow), never a dangling arrow. In TTB, terminators sit in a side column (T5).
3. **Diverge-then-converge.** Each branch has two or three unique steps, then both paths land on the **same** downstream step and the process continues as one line. Wire both branch tails into that shared step (`right → left` in LTR, T3 in TTB) — do not duplicate the shared step per branch. If the tails would arrive from different sides, the farther one is a go-to.

Map every branch and platform handoff as its own discrete step. Never collapse two outcomes into one box, and never bury a fork in a note.

### Label every branch

Every connection leaving a conditional gets a `label` (see Labels under each grammar): one to three words, one is ideal. Labels are what make a branch readable without opening a single step.

---

### The push plan

Every proposal that leads to a write ends with this block, before the approval question. Same three verbs every time, `Remove: nothing` spelled out, exact counts from the proposal above it, one sample row with every field the push will set.

```
Push plan: Workflow canvas, then a second block for anything created on other canvases
Add:     <n> <things> (<names, or the first five and "+n more">)
Change:  <n> <things> (<what changes on them>)
Remove:  <n> <things> (<names>)   or: nothing
Sample:  <one row as it will land, every field>
Nothing is written until you approve. Approve to push, or edit the list.
```

The proposal in chat (steps, orientation, conditional trace, handle table) ends with one block for the Workflow canvas (sections, steps, connections, the handle pass) and one for whatever the build creates elsewhere (roles with rates, tools, entities and attributes). The push writes exactly what the block says. Anything discovered mid-push that is not in the block is reported, not pushed. When a push is split into batches, the block says "in N batches", one approval covers them, and a failed batch stops the rest and reports.

---

## Connectors — the handle table and the handle pass

Connectors carry the visual grammar of the map, and handles are the only part of the layout you set directly. Two mechanics matter:

- `create_process` (and `create_connections`) accept **only** `from`, `to`, and `label` on a connection. Handles are **not** accepted there and never land at build time.
- `source_handle` and `target_handle` (`top` / `bottom` / `left` / `right`) exist only on `update_workflow`, keyed by connection ID. `list_steps` returns connection IDs, targets, and labels, but **not** the current handles — so the plan's handle table is the only record of what the map should look like, and it is applied verbatim.

### The handle table — a required part of the proposal

Before building, the proposal in chat includes the conditional trace (and the grid sketch when required) and a table with one row per connection: `from → to`, rule (D, A, B, C, or go-to), `label`, `source_handle`, `target_handle`. The user approves it with the rest of the plan; the handle pass applies it; the changelog records it. This is what makes the layout reproducible and reviewable instead of vibes.

Worked example 1 — LTR, a sales stage with a three-way score and a manager approval. Before this grammar, the map had the 80+ line cutting under the manager diamond's lines and three lines converging on "Close deal as lost" from three sides.

Conditional trace:

```
What is the vetting score?: continue = ✅80+ → Move deal to Contract Sent · above = 50–79 → Does the manager approve moving forward? · below = ❌Under 50 → Close deal as lost and set reason
Does the manager approve moving forward?: continue = ✅Approve → Move deal to Contract Sent · go-to = ❌Decline, 4 days → Go to: Close deal as lost (would cross the spine)
```

| From → To | Rule | Label | Source | Target |
|---|---|---|---|---|
| Run intro call in Revenue Hero → Sync meeting outcome to HubSpot | D | — | right | left |
| Sync meeting outcome to HubSpot → Auto-fill playbook from Grain transcript | D | — | right | left |
| Auto-fill playbook from Grain transcript → Attest AI fields and finish vetting section | D | — | right | left |
| Attest AI fields and finish vetting section → What is the vetting score? | D | — | right | left |
| What is the vetting score? → Move deal to Contract Sent | D | ✅80+ | right | left |
| What is the vetting score? → Does the manager approve moving forward? | D | 50–79 | right | left |
| What is the vetting score? → Close deal as lost and set reason | D | ❌Under 50 | right | left |
| Does the manager approve moving forward? → Move deal to Contract Sent | D | ✅Approve | right | left |
| Does the manager approve moving forward? → Go to: Close deal as lost | go-to | ❌Decline | right | left |
| Does the manager approve moving forward? → Go to: Close deal as lost | go-to | 4 days | right | left |
| Close deal as lost and set reason → End: Closed Lost | D | — | right | left |

`steps` order: the four spine steps, the vetting diamond, Move deal to Contract Sent (continue), the manager diamond (above), Close deal as lost (below), End: Closed Lost, Go to: Close deal as lost.

Read it back: every connection is `right → left`. The three outcomes of the vetting diamond leave its right handle and land on the row (80+), above it (50–79, the manager diamond) and below it (Under 50, Close deal). The manager diamond's Approve rejoins the row from the left. Its Decline and 4-days outcomes would have had to cross the spine to reach Close deal below, so they end in one go-to step. Eleven connections, one go-to, zero crossings.

Worked example 2 — TTB enrichment waterfall with deep branches (the "Signup Phone Lookup" pattern). TTB keeps a lane column, since side lanes are the vertical form of exception C.

| From → To | Pattern | Dist | Lane | Label | Source | Target |
|---|---|---|---|---|---|---|
| Has LinkedIn URL? → Find mobile by LinkedIn | T2 | adj | — | yes | bottom | top |
| Has LinkedIn URL? → Has name + work domain? | T2 | adj | — | no | bottom | top |
| Has name + work domain? → Find mobile by name + domain | T2 | adj | — | yes | bottom | top |
| Has name + work domain? → Has work email for LinkedIn lookup? | T9 | deep | right lane A | no | right | top |
| Find mobile by LinkedIn → AI Ark found a phone? | T3 | adj | — | — | bottom | top |
| Find mobile by name + domain → AI Ark found a phone? | T3 | adj | — | — | bottom | top (merge) |
| AI Ark found a phone? → Upsert phone to Attio | T9 | deep | left lane | yes | bottom | top |
| LinkedIn known for fallback? → Has work email for LinkedIn lookup? | T6 | peer | — | no | right | left |
| Has work email for LinkedIn lookup? → Return: no phone found | T9 | deep | outer-right lane | no | right | right |
| Prospeo found a mobile? → Upsert phone to Attio | T9 | deep | mid lane | yes | bottom | right |
| Prospeo found a mobile? (LeadMagic path) → Upsert phone to Attio | T9 | deep | mid lane (merge) | yes | left | right |
| Prospeo found a mobile? → Go to: Return: no phone found | go_to | — | — | No | right | left |

Read it back: adjacent outcomes drop bottom → top; the deep "no" from "Has name + work domain?" exits right and falls down its own lane into a step several rows below; both "yes" paths into the Attio upsert share one lane and one handle; the outermost "no" runs down the section's edge into the terminator's side; the one line that would have crossed the middle became a go-to step.

### The handle pass — two calls

Immediately after `create_process`, in the same turn:

1. `list_steps` with `section_id` and `include: ["connections", "connections.connection_id", "connections.to_step_id", "connections.to_step_name", "connections.label"]`. Match each returned connection to its handle-table row by from-step, to-step, and label.
2. **Call one, the default.** `update_workflow` with a `connections` array of `{ id, source_handle, target_handle }` for **every** connection id, all set to the default (`right`/`left` in LTR, `bottom`/`top` in TTB). No exceptions, no judgment. Batches of 25.
3. **Call two, the exceptions.** `update_workflow` with only the rows the table marks A, B or C, by id, with their handle pairs.
4. Record the ids in both calls. The API does not read handles back, so the two successful calls against every id are the verification. A connection missing from call one still carries Puzzle's nearest-side default, and the build is not done.

When you add or rewire connections later (`create_connections`, `update_workflow` with `from_step_id`/`to_step_id`), run the same two calls on the ids you touched.

### The visual check — look at what you built

The handle table is a prediction; Graphviz decides where steps land. After the handle pass, look:

1. Get a screenshot of the section, in this order: the built-in browser (open the section `url` from `list_sections`); Claude in Chrome; computer use, screenshotting the Puzzle window already open on the desktop (read access is enough, no clicking needed); the user, asked for a screenshot. If none of the four is possible, say so, and the changelog entry says "layout unverified".
2. Screenshot the whole section (zoom the canvas to fit; several screenshots for a large map).
3. Trace every connector against the handle table. Flag any: crossing another connector; running through or along a step it doesn't connect; entering a step from the wrong side; leaving a diamond from its top or bottom; a backward connector longer than one step; two lines into one target from different sides; hooking around a corner to reach its handle.
4. Fix each flagged connector with `update_workflow` (the handle pair, or an exception C arc) or replace it with a go-to step. Update the handle table to match.
5. Screenshot again. Repeat until the trace is clean, then report what you changed in the changelog.

Do not hand the user manual-drag instructions as a fix. Every fix is a handle, the `steps` order, or a go-to step.

---

## Go-to steps — jumps without the spaghetti

When a step loops back to anything **other than the step immediately before it**, do not draw a connector — a backward arrow stretches across the map, crosses everything in its path, and turns the diagram into spaghetti. Use the `go_to` step type instead. This rule applies to **every** loop-back longer than one step, whatever caused it: a rework branch off a conditional, a retry, a restart, an escalation that re-enters earlier in the flow.

How to build one:

1. **Create the go-to step as an extension of the looping step** — a new step of type `go_to`, connected forward from the step where the loop happens (normal short connector: right→left on a horizontal map, bottom→top on a vertical one).
2. **Name it after its destination**: "Go to: [exact name of the target step]" — e.g. "Go to: Submit intake form". The name is how the map reads without any arrow.
3. **Spell out the destination in the note**: name the exact target step (and its section if ambiguous), why the flow returns there, and the condition that sent it back. The note is what lets the user wire the jump themselves in the go-to step sidebar — write it so there's zero guesswork about which step to pick.
4. **No backward connector.** The go-to step is the terminus of that branch on the canvas; the jump itself is configured in the sidebar, not drawn. Label the connection *into* the go-to step like any post-conditional branch (1–3 words).

The one-step rule cuts both ways: to the step immediately before, a `top → top` connector (exception B) reads fine and a go-to step would be overkill; any farther, always the go-to step.

**Go-to steps also fix unavoidable crossings.** When a *forward* branch can't reach its target without crossing another connector — no free lane, no handle pair that avoids it — use a go-to step to the target instead of the connector, built the same way (named "Go to: [target]", destination in the note). Typical cases: several branches that all end at one shared terminator from different rows, where only the nearest row connects directly and the others get a go-to; a conditional above the spine whose exit must reach a terminator below it; a branch that would cut through a sub-row.

---

## Titling steps

Title every step as a **verb-first phrase, roughly four to eight words** — enough detail to name the action, never a paragraph. "Pull active-user rows from Postgres" not "Postgres." "Reconcile invoices against closed deals" not "Reconciliation." A reader scanning the map should understand the whole flow from titles alone. Where it helps, the title can carry the acting role ("CSM sends onboarding kickoff email" reads fine at seven words); otherwise the role association covers it. The note carries the detail.

---

## Step type

Set a `type` on every step so the canvas renders the right visual vocabulary. Valid types: `task`, `email`, `form`, `meeting`, `phone`, `chat`, `video`, `document`, `sms`, `notification`, `payment`, `research`, `database`, `delay`, `conditional`, `delegate`, `sequence`, `signal`, `go_to`, `link`, `webpage`, `workflow`, `audio`, `alias`, `tag`. Match the type to what the step actually is — an email step should look like an email step, a payment step like a payment step, and every fork is a `conditional`. Don't default everything to `task` when a specific type fits.

---

## Executor

Every step gets an `executor` — the field most often skipped, so set it explicitly on every step:

- **Person** — a human does this step manually.
- **Automation** — software runs it automatically.
- **AI Agent** — an agent runs it.

The executor split drives costing, layout, and attributes: manual (Person) steps carry duration + frequency and a responsible role; Automation/AI Agent steps hang as drops (exception A) in hybrid layouts and carry the attributes they populate.

---

## Roles — full RACI, not just the doer

Puzzle models role involvement as RACI: `link_to_steps` with `type: role` takes `involvement: responsible | approver | consulted | informed`. A thorough build assigns all four where they genuinely apply, not just the responsible role.

- Pull role IDs from `list_teams` (with `include: ['roles.id', 'roles.name', 'roles.hourly_rate']`), and pull the reporting lines (role connections) — hierarchy is what lets you infer approvers.
- **Responsible** — the role that performs the work. Every Person step gets exactly one. Usually the function that owns the work (CEO, Program Coordinator, Community Manager, Operations Manager); for a process anyone making operational changes runs, the workspace's generic operator role is the right owner. `role_ids` on the step in `create_process` covers this; patch with `link_to_steps`.
- **Approver** — the role that signs off. Infer from hierarchy: usually the responsible role's manager per the Team Canvas reporting lines, or the role responsible for a downstream approval/review conditional. Assign on steps where sign-off is real: approval conditionals, irreversible actions (send, pay, publish, delete), and threshold decisions. One approver per step.
- **Consulted** — roles whose input shapes the work (two-way). Infer from surrounding steps: the roles responsible for the steps immediately upstream and downstream of this one, and any role whose branch this step's output feeds. If the step consumes another role's work product or its outcome changes how they work, that role is consulted.
- **Informed** — roles that need to know the outcome (one-way). Infer from the rest of the flow: roles that own later steps in the process, the owner of the section/process as a whole, and the receiving role at any handoff or platform transition.
- **Don't RACI-spray.** Responsible is mandatory on every Person step; A, C, and I only where the relationship is real. A five-step process where every role is consulted on every step is noise, not documentation. If the inference isn't obvious, propose your best-guess RACI table in the intake round and let the user correct it.
- **Add, don't replace.** Before bulk-assigning on an existing process, check existing roles with `list_steps` (`include: ['roles.role_id', 'roles.role_name', 'roles.involvement']`) so you add alongside rather than clobber.
- For human-in-the-loop checkpoints inside an automated process, assign the responsible human role to just those checkpoint steps, with the approver on the checkpoint if sign-off escalates.

**If a mentioned role doesn't exist on the Team Canvas, create it — with an hourly rate.** Research the average hourly rate for that role (salary data converted to hourly is fine; note the basis), present it in the intake round for confirmation, then create the role via `create_org_structure` — nested in the right team, or in `standalone_roles` (pass `teams: []`) if it belongs to no team — with `hourly_rate` set. Never create a rate-less role: the whole point is that the step cost calculator and section cost calculator show a real number the moment the map lands.

---

## People — when the user names actual humans

Steps are owned by **roles**, not people — but users often describe processes in terms of the humans who run them ("Sarah reviews it, then Marcus approves"). When actual people are named:

1. Resolve each person on the People Canvas via `list_people` (with `include: ['roles.role_name']` to see what roles they already hold).
2. If the person exists and holds a role, use that role on the step. If they hold several, or the right one isn't obvious, it's an intake question.
3. If the person isn't on the People Canvas, or their role is unknown, **ask in the intake round what role they're in** — never invent a role for a named person, and never attach a person's name to a step in place of a role.
4. Create missing people via `create_people` and attach them to their role via `add_person_roles` — that way the map shows both the accountable role and the human currently filling it, and role hourly rates keep the costing intact when the person changes.

The rule of thumb: people change, roles persist. The role owns the step; the person is linked through the role.

---

## Delay steps — model real wait time, don't invent it

The `delay` step type exists to make wait time visible: approval turnaround ("wait 2 business days for legal sign-off"), shipping windows, cooling-off periods, batch schedules ("runs every Monday"). Wait time is often where the real process cost hides, so when the user **explicitly describes waiting** — a turnaround, a hold, a "then we wait for X" — model it as a `delay` step with the wait noted in the step name and note.

But **do not overuse them**: only add a delay step when the wait is explicitly mentioned in the process description or confirmed in intake. Do not speculatively insert delays between every handoff — an ordinary handoff is just a connection, and a map cluttered with imagined delays is worse than one with none. If you suspect a significant unstated wait (e.g. an approval that clearly can't be instant), raise it as an intake question rather than adding the step on your own.

---

## Frequency and time → automatic process costing

On every **Person/manual** step, set `duration` (minutes) and `frequency` (times per month). Estimate from the nature of the action — a quick form fill is 1–2 min, a review or judgment step 3–5 min — and confirm estimates in the intake round rather than asking cold. If the user gave neither number and you can't reasonably estimate, it's an intake question; never build a manual step with empty cost inputs.

This is what turns a map into a costed operation. Without it you have a diagram; with it Puzzle rolls up labor cost automatically. Skip it only on Automation/AI Agent steps unless the user wants those costed too.

---

## Attributes — the data every step reads and writes

Attributes are what make a step concrete instead of hand-wavy. For every step that touches structured data:

- **Manual steps** — which fields does the person actually fill out or update in that tool? (e.g. "Update deal stage, close date, and amount in the CRM.")
- **Automation steps** — which fields does the automation populate in the target system?

Work the data model in this order:

1. Check `list_entities` and `list_attributes` for the tools involved.
2. If the entities/attributes exist, associate them to their steps via `link_to_steps` with `type: attribute` and each `attribute_id`. (Attributes always link post-build — `create_process` doesn't carry them.)
3. If they don't exist, **propose them**: draft the entity (Contact, Deal, Ticket, Order) and its attributes with sensible field types, present the proposal in the intake round for approval, then create via `create_data_model` (entities with nested `attributes`; use `standalone_attributes` with `entity_id` to add fields to an existing entity) and link them to the steps.

Only model data the process genuinely depends on. Don't over-model — but never leave a data-touching step with zero attributes either.

---

## Tools

Link every tool a step touches — via `tool_ids` (and `primary_tool_id`) on the step in `create_process`, or `link_to_steps` with `type: tool` when patching. This is the other field skipped by default — verify it landed.

- Resolve all tool IDs in one `list_tools` call (comma-separated names).
- A step can carry multiple tools. Tag every system the step actually uses.
- **If a mentioned tool isn't in the workspace, add it** before the build — `link_to_steps` auto-adds catalogue tools, and `update_account_tools` / `create_tool_structure` covers the rest — so the Tools Canvas stays the complete inventory and the association lands on the step.

---

## Mini-SOP notes

Every step gets a note written so anyone reading the map knows exactly how the step is configured and why. Use a consistent four-part structure:

> **Purpose** — why this step exists (and why it's configured this way).
> **Inputs** — what it needs to start.
> **Procedure** — the actual how, in order. Name the responsible role.
> **Output** — what it produces / hands to the next step.

Structure can land in the `create_process` call (short one-liners) with the full mini-SOP backfilled via `update_workflow` — but the build isn't done until the notes pass is done.

Also write a **section overview note**: why the process exists, when it triggers, who owns it, and the quality bar. The section note is the canonical home for report templates or system context the process relies on.

Write notes plainly: no corporate filler (powerful, seamless, robust, leverage, unlock, empower, streamline), no padding. Anyone reading a note should be able to run the step.

---

## Status

Set step `status` deliberately: **Live** for steps running in production today; **Draft**/**In_Progress**/**Testing** for future or in-flight states. A process documenting something already operating should be Live across the board; a proposed future-state process should not claim Live. If the prompt doesn't make it obvious, it's an intake question.

---

## Changelog — memorialize every build

When the process is built (or meaningfully changed), record it. Always. Use `create_changelog_entries` with a Markdown body (title as the first heading) that captures:

- What the user asked for, in substance (the process, the decisions made in intake: orientation and why, rates, attributes, branch logic)
- What was created or changed, across **all** elements: section and steps, connections and labels, the handle table as applied, what the visual check found and fixed, roles created (with rates), tools added, entities/attributes created and linked, cost inputs set
- Why — the rationale behind any judgment calls

Set `status: completed`, set the owner (`person_id` from `list_people`), then use `update_changelog_entries` to associate the relevant steps and tools so the entry is wired into the map. A build without a changelog entry is an incomplete build.

---

## After the build: offer to share

End the closing message with one line: "Want this shared? I can make a shared view with this section, the team that owns it and the tools it uses." Nothing more. If the user says yes, `share-the-map` derives the view from the workspace, asks who it is for, and publishes after approval. If they say nothing, nothing is published. The offer never becomes a question in the intake round.

---

## Quick pre-flight checklist

Before you call it done, confirm every step has:

- [ ] A verb-first title, four to eight words
- [ ] A type that matches the action (forks are `conditional`)
- [ ] A status (Live vs Draft/In_Progress/Testing)
- [ ] An executor (Person / Automation / AI Agent)
- [ ] A responsible role on every Person step (added, not replaced), with an hourly rate on the role
- [ ] Approver on sign-off and irreversible steps; consulted/informed where the relationship is real (no RACI-spray)
- [ ] Tools linked on every step that touches one
- [ ] Attributes linked on every step that reads or writes data
- [ ] Duration + frequency on every Person step (costing)
- [ ] A mini-SOP note (Purpose / Inputs / Procedure / Output)

And the process as a whole:

- [ ] As few sections as possible: one up to about 25 steps; stages of 10 to 25 beyond that, cut at seams, connected across the boundary
- [ ] Trigger asked about (if unstated) — the first step is what kicks the process off
- [ ] Orientation chosen by shape (LTR timeline / TTB pipeline / LTR hybrid with drops) and stated with a reason
- [ ] Every conditional traced: continue on the row, branch above, terminator or skip below, go-to where it would cross; at most three outcomes, all labeled
- [ ] Grid sketched when there are three or more conditionals or any branch crosses another
- [ ] Every connection in the handle table with its rule (D, A, B, C, or go-to) and handle pair before building
- [ ] LTR: every connection `right → left` except automation drops (A), one-step loop-backs (B) and arcs past other steps (C); TTB: every connection `bottom → top` with the matching exceptions
- [ ] A target reached from conditionals on different rows connects directly from the nearest row only; the rest are go-to steps
- [ ] Any crossing that couldn't be designed away replaced with a `go_to` step
- [ ] `steps` array ordered: spine, then per diamond continue / above / below, shared terminators last
- [ ] No row wrapping and no manual-layout instructions to the user; a long linear spine is a reason to choose top-to-bottom
- [ ] Nothing enters a step from the "wrong" side; nothing leaves a diamond's top or bottom
- [ ] Visual check done: section screenshotted (browser, Chrome, computer use, or the user), every connector traced, fixes applied and re-screenshotted; or the changelog says the layout is unverified
- [ ] Named people resolved to roles on the People Canvas (created via `create_people` + `add_person_roles` if missing)
- [ ] Explicitly mentioned waits modeled as `delay` steps — and no speculative delays inserted
- [ ] Every conditional matched to its pattern: loop-back, full divergence, or diverge-then-converge
- [ ] Loop-back branches wired to the step before the conditional; terminal branches given real terminator steps; converging branches landing on one shared step
- [ ] Every loop-back longer than one step built as a `go_to` step named "Go to: [target step]", with the destination spelled out in the note — no backward connectors beyond `top → top` to the previous step
- [ ] Every post-conditional connection labeled (1–3 words)
- [ ] Handle pass executed as two `update_workflow` calls (default on every connection ID, then the exceptions), recorded by ID
- [ ] New roles created with researched, confirmed hourly rates
- [ ] New tools added to the Tools Canvas and linked
- [ ] Entities/attributes proposed, approved, created, and linked
- [ ] A section overview note (why / when / owner / quality bar)
- [ ] A changelog entry memorializing what was said and done — handle table included — with steps and tools associated
- [ ] The closing message ends with the one-line offer to share
- [ ] All of the above resolved through at most ONE intake round

---

## MCP mechanics that reliably work

- `create_process` in **one call** with sections + steps + connections, wiring via `temp_id` (more reliable than creating steps then connections separately). Connections accept `from`, `to`, and `label` only — set labels at build time. Set `direction` on the call. For adding to an existing section, pass the `section_id` directly instead of creating a new one.
- Step positions are computed by Graphviz from the connection graph and `direction`. There is no position field to set; shape the graph (see "Shaping the graph") and let the layout follow.
- Handles are set **only** via `update_workflow` on existing connection IDs (`connections` array: `id`, `source_handle`, `target_handle`; `from_step_id`, `to_step_id`, and `label` are also accepted for rewiring). Get the IDs from `list_steps` with `include: ["connections", "connections.connection_id", "connections.to_step_id", "connections.to_step_name", "connections.label"]`. `list_steps` does not return handles, so keep your handle table as the source of truth.
- `create_connections` (for patching an existing map) likewise accepts only `from_step_id`, `to_step_id`, `label` — follow it with the same handle pass.
- Steps in `create_process` carry `role_ids`, `tool_ids`, `primary_tool_id`, `duration`, `frequency`, `status`, `executor`, `type`, and `notes` directly — front-load everything the schema allows. Attributes are the exception: always a post-build `link_to_steps` pass.
- To rewire an existing arrow without deleting it: `list_steps` with connection includes to get the connection ID, then `update_workflow` with a `connections` array (`id`, `from_step_id`, `to_step_id`, `source_handle`, `target_handle`, `label`) to redirect in place.
- Capture returned step IDs immediately — every later `update_workflow`, `link_to_steps`, and changelog association needs them.
- `update_workflow` takes max 25 steps per call — batch accordingly on big processes, and split large `connections` arrays the same way.
- Edit in place. When extending a process, update existing steps and connections rather than tearing down and rebuilding — and run the two-call handle pass on every connection you add or rewire.
- Verify after building: `list_steps` with `include` for roles, tools, attributes, duration, frequency, and connections. A field missing from a response means you didn't request it, not that it's empty — include what you're checking.
