---
name: build-puzzle-process
description: Build thorough, well-structured processes in any Puzzle workspace via the Puzzle MCP. Load whenever the user asks to "build out this process", "map this in Puzzle", "document this workflow", "create a process for X", or when a workflow needs to become a Puzzle section with steps, executors, roles, tools, conditionals, attributes and notes. Also load when editing or extending an existing Puzzle process. Covers one consolidated intake, one section per process, conditional branches and go-to steps, orientation chosen by shape, a grid sketch traced for zero crossings, a coded connector grammar with a handle table and a mandatory post-build handle pass, a visual check of the built map, step typing and titling, RACI roles with hourly rates, costing inputs, attributes, tools, triggers, delay steps and a changelog entry. When in doubt building anything in Puzzle, use this skill.
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
5. **Sketch the grid, then trace every connector.** Before writing the handle table, draw a rough text grid of where each step should land (rows × columns — see "The grid sketch"). Classify every connection by distance (adjacent / same-row peer / deep), assign lanes to the deep ones, and trace every connector on the sketch. The acceptance bar is **zero crossings and zero connectors passing through a step**. Where a crossing can't be avoided, replace that connector with a `go_to` step.
6. **Propose the full process in chat.** Every step fully specified: name, type, status, executor, roles, tools, attributes, frequency, duration, and a one-line note — plus the orientation (with the reason), the branch wiring, the **grid sketch**, and the **handle table** (see "Connectors"): one row per connection with its pattern code, distance class, lane, label, source handle, and target handle. Let the user evaluate the structure and the layout before anything is written to Puzzle.
7. **Create missing canvas objects first.** New roles (with hourly rates) on the Team Canvas, new tools on the Tools Canvas, new entities/attributes in the data model. These must exist before the workflow build so IDs are available for linking.
8. **Build in one call.** Use `create_process` with the full `sections`, `steps`, and `connections` arrays in a single call, wiring connections via `temp_id` references, with `label` set inline on every connection that needs one. Include `role_ids`, `tool_ids`, `duration`, `frequency`, `status`, `executor`, `type`, and `notes` directly on each step. Set `direction`. Capture the returned step IDs. (Connections in `create_process` carry only `from`, `to`, and `label` — handles come next.)
9. **Run the handle pass.** `list_steps` on the new section with `include: ["connections", "connections.connection_id", "connections.to_step_id", "connections.to_step_name", "connections.label"]` to capture every connection ID, then one `update_workflow` call (split into batches of 25 on big maps) that sets `source_handle` and `target_handle` on **every** connection exactly as the approved handle table says. This is a named, mandatory step — not a "fix any misses" afterthought. A map with default handles is not built.
10. **Look at the map.** Open the section in the built-in browser, screenshot it, and trace every connector (see "The visual check"). Fix any crossing, pass-through, or hook via `update_workflow`, then screenshot again. The handle table is a prediction of the layout; the screenshot is the proof.
11. **Link what create_process can't carry.** Attributes always link post-build via `link_to_steps` with `type: attribute`. Approver, consulted, and informed roles also link post-build via `link_to_steps` with `type: role` and the right `involvement` (the `role_ids` array in `create_process` covers responsible only). Verify roles and tools landed; patch any misses with `link_to_steps`.
12. **Verify.** Re-run `list_steps` with includes for roles, tools, attributes, duration, frequency, notes, and connections. Confirm every connection in the handle table received a successful update (the API does not read handles back, so your record of the pass is the verification). Fix any label or handle that reads wrong via `update_workflow`.
13. **Memorialize in the changelog.** Always, including the handle table and the result of the visual check. See "Changelog" below.

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

- One section
- Trigger known (ask if not stated) — the first step of the map is what kicks the process off
- Orientation chosen by shape (LTR timeline / TTB pipeline / LTR hybrid with drops) and stated with a reason
- Named people mapped to roles (ask if a person's role is unknown)
- Explicit waits modeled as delay steps (and only explicit ones)
- Every conditional branch resolves somewhere (loop back, diverge, or converge)
- Loop-backs farther than three steps modeled as `go_to` steps, not connectors
- Grid sketched and every connector traced with zero crossings before building
- Every connection assigned a pattern code, distance class, lane (if deep), and handle pair in the handle table before building
- Every post-conditional connector labeled
- No row wrapping and no manual-layout instructions to the user
- Handle pass executed via `update_workflow` on every connection ID, then verified
- Visual check done: screenshot taken, every connector traced, fixes applied
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

## One section per process — always

A process lives in **one section**. Do not split a single process across multiple sections. Left unattended, AI builders get "section-happy" and fragment one process into several, which breaks the visual story and the costing rollup. One section, every step inside it. This is non-negotiable unless the user explicitly asks for multiple.

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
- **Handle grammar** — the source handle is the side the arrow *leaves*; the target handle is the side it *arrives*. The router draws orthogonal lines between them; your whole job is choosing the pair that needs the fewest bends, reads in the direction of flow, and never crosses another connector.
- **Flow-facing side** — the side of a step that faces the direction of flow: **right** in LTR, **bottom** in TTB. Its opposite is the **entry side**: left in LTR, top in TTB.
- **Distance class** — every connection is one of: **adjacent** (target is on the next rank, facing the source), **same-row peer** (target sits beside the source on the same rank), or **deep** (target skips one or more ranks, or sits in a far column/row, so a direct line would pass through or beside other steps).
- **Lane** — an empty corridor a deep connector travels in: in TTB, a vertical corridor between columns or along the outer left/right edge of the section; in LTR, a horizontal corridor above or below a row. Lanes are what keep long connectors from cutting through steps.
- **Merge** — two or more connectors headed to the same target sharing one lane and one target handle, so they read as one line instead of crossing.

### Choosing the orientation

If the user hasn't said, ask in the intake round — but recommend, and state the recommendation as "this shape, because …":

- **left_to_right** when the map reads as a timeline of mostly Person steps with a handful of conditionals, where role and time badges matter. The default for any process where a reader should see "who does what, in order."
- **top_to_bottom** when the process is a pipeline of Automation / AI Agent steps with a conditional every two or three steps, branches that reconverge within a row or two, and terminators like "Skip — no match." Vertical reads like a flowchart and keeps each fork's outcomes side by side. Also prefer it for a long, mostly linear spine (roughly twelve or more spine steps): since the skill never wraps rows, a long LTR spine becomes one endless row, whereas a long column scrolls naturally.
- **Hybrid** is not a third `direction` value; it is LTR with drops. Choose it whenever a Person-driven spine triggers automations.

Set it on `create_process` via `direction`.

### Connector principles — apply before any pattern code

These govern both orientations. The pattern codes below are how they play out in each direction.

1. **Conditional outcomes share the flow-facing handle.** Every outcome of a conditional leaves the same side: **right** in LTR, **bottom** in TTB. Each outcome enters the side of its target that faces it: **left** in LTR, **top** in TTB. The layout engine stacks the targets (above/below the row in LTR; left/centre/right in TTB) and the router splits the line. Do **not** send one outcome out the right and another out the bottom of an LTR diamond, and do not send TTB outcomes out the sides by default. The diamond shape and the labels already say "exclusive fork"; handles don't need to.
2. **Pick handles by distance, not only by pattern.** Classify every connection as adjacent, same-row peer, or deep (see Vocabulary):
   - **Adjacent** → the default handles (LTR `right → left`, TTB `bottom → top`), shared by all outcomes of a conditional.
   - **Same-row peer** → side to facing side (LTR: rare, since peers stack vertically; TTB: `right → left` or `left → right`).
   - **Deep** → a **bypass**: leave through the side that faces an open lane, travel the lane, and enter the target on its entry side or on the side that faces the lane. In LTR this is usually `top → top` (arcing over the row) or `bottom → bottom` (sweeping under it). In TTB it is a side exit (`right` or `left`) into an outer lane, dropping into the target's `top`, or entering its facing side (`right`/`left`) when the lane runs beside it.
3. **Plan lanes before you write handles.** Give every deep connector a lane. One lane per destination. Connectors headed to the same target **merge** into that lane and share the target handle; they never run parallel lanes that cross each other. Outer lanes (the section's far left/right edge in TTB, above/below everything in LTR) are the safest because nothing sits in them.
4. **No crossings, no pass-throughs.** A connector must never cross another connector and never run through or along the face of a step it isn't connecting. If the grid trace shows a crossing you can't remove by choosing a different lane or handle, replace that connector with a `go_to` step (see "Go-to steps") — even when the target is downstream, not a loop-back. Clean beats literal.
5. **Parallel fan-outs are the only non-conditional shared split.** One step feeding N steps that all happen uses the same flow-facing handle (L6 / T-rules), just like a conditional. The difference is carried by step type (a fork is a `conditional`) and labels, not handles.

### The grid sketch

You can't see the canvas while planning, so draw it. Before the handle table, write a small text grid: one cell per step, rows = ranks in the direction of flow, columns = the branches Graphviz will spread them into. Then draw each connector on it, including its lane. Example (TTB):

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

Trace each line. If two lines cross, or a line runs through a step, change the lane, change the handle, reorder the `steps` array, or use a `go_to` step. Only propose the handle table once the trace is clean. The sketch is a prediction of what Graphviz does; the visual check after the build confirms it.

### Left-to-right grammar

Every connection in an LTR map matches one of these patterns. Cite the code in the handle table.

- **L1. Spine.** Every spine connection is `right → left`. Steps sit on one row, evenly spaced. Only override on the patterns that follow.
- **L2. Conditional — all outcomes leave right.** Every outcome of a conditional, whether 2 or 3, leaves the diamond's **right** handle and enters the **left** of its target: `right → left`, labeled. The continuing / most common outcome keeps the row; the others stack above and below. Each branch then runs `right → left` as its own mini-row. This covers yes/no forks, peer outcomes (two tracks, neither "main"), and three-way splits alike. More than three outcomes → make it a TTB map or split the conditional.
  - **L2a. Branch with its own steps that rejoins.** The branch's last step leaves `right` and enters the **left** of the rejoin step (`right → left`); the router carries it back to the row. Never rejoin into the bottom or top of a spine step unless it's a deep bypass (L4).
  - **L2b. Short skip branch.** An outcome that lands on a spine step one or two steps ahead with nothing on the row in between blocking it: `right → left`, merged into the target's left handle.
- **L3. (Retired.)** Peer outcomes are L2. Kept as a number so older handle tables still read.
- **L4. Deep bypass — top → top / bottom → bottom.** A branch whose target is several steps downstream (it jumps past steps, conditionals, or sub-rows) must not cut through them. Leave the source from **top** and enter the target's **top** (arcing over everything in between), or `bottom → bottom` if the space above is taken. Pick the side whose lane is empty. Several deep branches to the same target merge into one lane on the same side. If the target sits on an upper or lower row and the lane approaches it from the side, enter its **left**.
- **L5. (Retired.)** Multi-way outcomes are L2.
- **L6. Parallel fan-out.** One step feeding N parallel next steps (all happen, no condition): every connection `right → left`; the targets stack in rows above and below the source's row and the router fans them. This is the same handle pair a conditional uses (L2); the source being a non-conditional step, with no labels, is what says "all of these happen." Fan-out branches may each continue as their own mini-spine `right → left` and may converge later (`right → left` into the shared step).
- **L7. Automation drop.** Automation / AI Agent steps triggered by a spine step hang **below** it: `bottom → top` from the trigger to the first automation, and `bottom → top` again for each automation in the chain, forming a column. If the chain feeds back into the spine, its last step enters the next spine step's **left** (`right → left`). If the space below is already taken by a branch row or a bottom lane, the drop may go above instead: trigger `right` (or `top`) → automation `left`, and the automation re-enters the spine `bottom → top`. Below is the default; above is the fallback.
- **L8. No wrapping — ever.** The spine is one row, however long. Never break a spine onto a second line, never wire a `bottom → top` "wrap" connection between consecutive spine steps, never ask the user to drag steps. If a spine is long enough that this hurts, the answer is the orientation choice above (go top-to-bottom), not a wrap.
- **L9. Loop-back within three steps.** From above: `top → top`, arcing over the spine. From below: `bottom → bottom`, sweeping under it. Beyond three steps, no connector at all — a `go_to` step (see "Go-to steps").
- **L10. Converging triggers and converging exits.** Two entry steps stacked on the left both enter the first spine step `right → left`. Several branches from different steps that land on one shared step (a shared terminator, a common rejoin) **merge**: they share one lane and one target handle — the left when they arrive along the flow, the top (or bottom) when they arrive by a deep bypass lane (L4). Never let two converging lines approach from different sides if that makes them cross.
- **L11. Labels.** Every connection leaving a conditional carries a label of one to three words; the house style prefixes them with ✅ / ❌ / ➕ where it helps ("✅Yes", "❌No", "➕New", "✅Existing"). Longer labels only when they carry the routing logic itself ("Stalled (25+ L14D)", "no company → skip (under 25)"). Ordinary spine connections in a timed sequence carry timing labels ("Day 0", "+5 days", "cohort close"). Branch labels sit on the horizontal run of the connector, so word them to read there.
- **L12. Never in LTR.** Never enter a step from its **right**. Never leave a spine step from top or bottom for an adjacent spine connection (top/bottom exits are for drops, L7; deep bypasses, L4; and loop-backs, L9). Never split a conditional's outcomes across the right and bottom handles — they all leave right. Never let a connector cross another connector or run through a step.

### Top-to-bottom grammar

- **T1. Spine.** Single centre column, every spine connection `bottom → top`.
- **T2. Conditional — all outcomes leave bottom.** Every outcome whose target is on the next row leaves the **bottom** handle and enters the **top** of its target. Outcomes sit in columns: the continuing/most-common outcome under the diamond, the others to the left and right. Two outcomes → left and right (or centre and one side); three → left, centre, right. Labels sit on the horizontal run. Side handles are **not** used for adjacent outcomes — only for same-row peers (T6) and deep bypasses (T9).
- **T3. Converge.** A side-column branch rejoins in whichever way doesn't cross anything:
  - **From above** (the rejoin step is on a lower row than the branch's last step): `bottom → top`, merging into the rejoin step's top alongside any other line arriving there. This is the common case.
  - **Same row** (the branch's last step sits beside the rejoin step): horizontally — from the left column `right → left`, from the right column `left → right`.
  - **From a lane** (the branch arrives via a deep bypass lane running beside the target): into the side that faces the lane.
- **T4. Side detour with its own steps.** A branch of two or more steps runs down its own side column `bottom → top`, parallel to the spine, and rejoins per T3.
- **T5. Terminators.** "Skip — …" / "End — …" steps live in a side column and dead-end there with no outgoing connection. Keep them off the spine column so the spine reads as the happy path.
- **T6. Exception off a non-conditional step.** An exception that fires from an ordinary step leaves that step's side and enters the **opposite side** of a peer step on the same row: `left → right` or `right → left`, labeled with the exception condition ("on batch run failure").
- **T7. Labels.** Same rule as L11; lowercase, terse labels are the house style in TTB ("matched", "no match", "has domain", "no domain", "hit", "miss").
- **T8. Never in TTB.** Never use `left`/`right` for an adjacent spine connection. Never use `top`/`bottom` for a same-row converge. Never enter a step from its bottom. Never let a connector cross another connector or run through a step.
- **T9. Deep bypass — side exit into a lane.** When a conditional outcome's target is several rows down or in a far column (so a `bottom → top` line would cut through the steps in between), leave the diamond from the **side facing the target's column** (`right` or `left`), run horizontally to an open lane, travel down the lane, and enter the target's **top** if the lane lands above it, or the target's **facing side** if the lane runs beside it. Use outer lanes (the section's far edge) for the deepest jumps. Multiple deep outcomes headed to the same target (e.g. several "no" branches into one "Return: no phone found" terminator) merge into one lane and one target handle. The normal pairing on a busy TTB diamond is: adjacent outcome out the bottom, deep outcome out the side.
- **T10. LTR's top → top in TTB terms.** The TTB equivalent of the LTR arc is a side lane: to get past a run of downstream steps without cutting through them, go out the side, down the lane, and back in. Never draw a long `bottom → top` line down the middle of a column that other steps occupy.

### Shaping the graph so Graphviz cooperates

Placement comes from the graph, so build the graph deliberately:

- List steps in the `steps` array in spine order first, then sub-rows / side columns in the order they should appear, then terminators. Graphviz ranks by connection but breaks ties by order.
- Give every branch a real target. A dangling branch collapses the layout.
- Keep the spine a single path: avoid two connections into the same spine step from the same side unless they are converging by design (L10, T3).
- Order steps so deep targets land at the edges: list a shared terminator (e.g. "Return: no phone found") last so Graphviz pushes it to the bottom/right, where outer lanes can reach it without crossing the middle of the map.
- Never add "helper" connections to force a shape — every connection must be a real handoff. If a shape can't be reached with real connections plus handles, it isn't a shape this skill produces; pick the orientation that reads best with the real graph and move on.
- For hybrids, connect the drop from the *triggering* step, not from the step after it, or Graphviz pulls the automation into the spine.

---

## Conditionals — every branch must land somewhere

Wherever the process forks, model it as a **conditional step** (type `conditional`), named as the question it answers: "Did eligibility pass?", "Is the invoice correct?". Then identify which of the three branch patterns applies — this is the single most common thing sloppy builds get wrong:

1. **Loop-back (the rework path).** One branch is a fix/follow-up that returns to earlier work — e.g. "Not approved → revise and resubmit." The follow-up step's outgoing connection goes **back to the step before the conditional** (or whichever earlier step gets redone). No dangling arrows, no dead-end "fix it" boxes. Distance rule: a connector is only right when the target is **three steps back or fewer** — any farther and it becomes a `go_to` step instead (see "Go-to steps"). Wire the connector per L9 (the loop-back arc is unchanged: `top → top` / `bottom → bottom`).
2. **Full divergence.** The two paths genuinely never recombine — each branch gets its own sequence of steps through to its own end. Terminal branches get a real terminator step (no role or tool; it just ends the flow), never a dangling arrow. In TTB, terminators sit in a side column (T5).
3. **Diverge-then-converge.** Each branch has two or three unique steps, then both paths land on the **same** downstream step and the process continues as one line. Wire both branch tails into that shared step (L2a rejoin in LTR, T3 in TTB) — do not duplicate the shared step per branch.

Map every branch and platform handoff as its own discrete step. Never collapse two outcomes into one box, and never bury a fork in a note.

### Label every branch

Every connection leaving a conditional gets a `label` per L11 / T7: one to three words, one is ideal. Labels are what make a branch readable without opening a single step.

---

## Connectors — the handle table and the handle pass

Connectors carry the visual grammar of the map, and handles are the only part of the layout you set directly. Two mechanics matter:

- `create_process` (and `create_connections`) accept **only** `from`, `to`, and `label` on a connection. Handles are **not** accepted there and never land at build time.
- `source_handle` and `target_handle` (`top` / `bottom` / `left` / `right`) exist only on `update_workflow`, keyed by connection ID. `list_steps` returns connection IDs, targets, and labels, but **not** the current handles — so the plan's handle table is the only record of what the map should look like, and it is applied verbatim.

### The handle table — a required part of the proposal

Before building, the proposal in chat includes the grid sketch and a table with one row per connection: `from → to`, pattern code (L1–L12 / T1–T10), distance class (adj / peer / deep), lane (for deep rows), `label`, `source_handle`, `target_handle`. The user approves it with the rest of the plan; the handle pass applies it; the changelog records it. This is what makes the layout reproducible and reviewable instead of vibes.

Worked example 1 — LTR with a yes/no conditional, a short skip, and one automation drop:

| From → To | Pattern | Dist | Lane | Label | Source | Target |
|---|---|---|---|---|---|---|
| Receive signed order form → Is the order over $10k? | L1 | adj | — | — | right | left |
| Is the order over $10k? → Route order for finance approval | L2 | adj | — | ✅Yes | right | left |
| Is the order over $10k? → Provision the customer workspace | L2b | adj | — | ❌No | right | left |
| Route order for finance approval → Provision the customer workspace | L2a | adj | — | — | right | left |
| Provision the customer workspace → Sync workspace record to Attio | L7 | adj | — | — | bottom | top |
| Provision the customer workspace → Send kickoff email to customer | L1 | adj | — | — | right | left |

Read it back: both outcomes leave the diamond's right handle; "Yes" stacks above the row and rejoins provisioning from the left, "No" goes straight to provisioning's left; the Attio sync hangs below its trigger; the spine carries on right→left.

Worked example 2 — TTB enrichment waterfall with deep branches (the "Signup Phone Lookup" pattern):

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

### The handle pass

Immediately after `create_process`:

1. `list_steps` with `section_id` and `include: ["connections", "connections.connection_id", "connections.to_step_id", "connections.to_step_name", "connections.label"]`. Match each returned connection to its handle-table row by from-step, to-step, and label.
2. One `update_workflow` call with a `connections` array of `{ id, source_handle, target_handle }` for **every** row. The schema caps `steps` at 25 per call; split the `connections` array into batches of 25 on big maps to be safe.
3. Record which connection IDs were updated. Because the API does not read handles back, that record is the verification — every row in the table must have a successful update against it before the build is called done.

### The visual check — look at what you built

The handle table is a prediction; Graphviz decides where steps actually land. So after the handle pass, look:

1. Open the section in the built-in browser (the step or section `url` from `list_steps` / `list_sections`). If the built-in browser is unavailable, use Claude in Chrome; if neither is available or the user isn't logged in to Puzzle there, ask the user for a screenshot instead.
2. Screenshot the whole section (zoom the canvas to fit if needed; take several screenshots for a large map).
3. Trace every connector against the handle table. Flag any: crossing another connector; running through or along a step it doesn't connect; entering from the wrong side (L12 / T8); hooking around a corner to reach its handle; doubling back through the step it left; two outcomes of one diamond split across different flow-facing handles.
4. Fix each flagged connector with `update_workflow` — change the handle pair, move it to another lane (e.g. `top → top` instead of `right → left`), or replace it with a `go_to` step. Update the handle table to match.
5. Screenshot again. Repeat until the trace is clean, then report what you changed in the changelog.

Do not hand the user manual-drag instructions as a fix. Every fix is a handle, a lane, step order, or a go-to step.

---

## Go-to steps — long loop-backs without the spaghetti

When a step deep in the process loops back to a step **more than three steps upstream**, do not draw a connector — a long backward arrow stretches across the map, crosses everything in its path, and turns the diagram into spaghetti. Use the `go_to` step type instead. This rule applies to **every** loop-back farther than three steps, whatever caused it: a rework branch off a conditional, a retry, a restart, an escalation that re-enters earlier in the flow.

How to build one:

1. **Create the go-to step as an extension of the looping step** — a new step of type `go_to`, connected forward from the step where the loop happens (normal short connector: right→left on a horizontal map, bottom→top on a vertical one).
2. **Name it after its destination**: "Go to: [exact name of the target step]" — e.g. "Go to: Submit intake form". The name is how the map reads without any arrow.
3. **Spell out the destination in the note**: name the exact target step (and its section if ambiguous), why the flow returns there, and the condition that sent it back. The note is what lets the user wire the jump themselves in the go-to step sidebar — write it so there's zero guesswork about which step to pick.
4. **No backward connector.** The go-to step is the terminus of that branch on the canvas; the jump itself is configured in the sidebar, not drawn. Label the connection *into* the go-to step like any post-conditional branch (1–3 words).

The three-steps rule cuts both ways: within three steps, a connector with proper handles (L9) reads fine and a go-to step would be overkill; beyond three, always the go-to step. Count steps along the main flow between the looping step and its target — branches don't count.

**Go-to steps also fix unavoidable crossings.** When a *forward* branch can't reach its target without crossing another connector — no free lane, no handle pair that avoids it — use a go-to step to the target instead of the connector, built the same way (named "Go to: [target]", destination in the note). Typical case: several branches that all end at one shared terminator from opposite sides of the map; the ones on the far side get a go-to.

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

The executor split drives costing, layout, and attributes: manual (Person) steps carry duration + frequency and a responsible role; Automation/AI Agent steps hang as drops (L7) in hybrid layouts and carry the attributes they populate.

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

- [ ] One section, all steps inside
- [ ] Trigger asked about (if unstated) — the first step is what kicks the process off
- [ ] Orientation chosen by shape (LTR timeline / TTB pipeline / LTR hybrid with drops) and stated with a reason
- [ ] Grid sketched; every connector traced on it with zero crossings and zero pass-throughs
- [ ] Every connection assigned a pattern code, distance class, lane (if deep), and handle pair in the handle table before building
- [ ] LTR conditionals: all outcomes leave **right** and enter the **left** of their targets (no right/bottom split)
- [ ] TTB conditionals: adjacent outcomes leave **bottom** and enter **top**; side exits only for same-row peers and deep bypasses
- [ ] Deep branches travel a lane (LTR `top → top` / `bottom → bottom`; TTB side exit into a lane) instead of cutting through downstream steps
- [ ] Connectors to the same target merge into one lane and one target handle
- [ ] Any crossing that couldn't be designed away replaced with a `go_to` step
- [ ] Automation drops hang bottom → top under their trigger
- [ ] No row wrapping and no manual-layout instructions to the user; a long linear spine is a reason to choose top-to-bottom
- [ ] Nothing enters a step from the "wrong" side for its orientation (L12 / T8)
- [ ] Visual check done: section screenshotted, every connector traced, fixes applied and re-screenshotted
- [ ] Named people resolved to roles on the People Canvas (created via `create_people` + `add_person_roles` if missing)
- [ ] Explicitly mentioned waits modeled as `delay` steps — and no speculative delays inserted
- [ ] Every conditional matched to its pattern: loop-back, full divergence, or diverge-then-converge
- [ ] Loop-back branches wired to the step before the conditional; terminal branches given real terminator steps; converging branches landing on one shared step
- [ ] Every loop-back farther than three steps built as a `go_to` step named "Go to: [target step]", with the destination spelled out in the note — no long backward connectors anywhere
- [ ] Every post-conditional connection labeled (1–3 words)
- [ ] Handle pass executed via `update_workflow` on every connection ID, then verified
- [ ] New roles created with researched, confirmed hourly rates
- [ ] New tools added to the Tools Canvas and linked
- [ ] Entities/attributes proposed, approved, created, and linked
- [ ] A section overview note (why / when / owner / quality bar)
- [ ] A changelog entry memorializing what was said and done — handle table included — with steps and tools associated
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
- Edit in place. When extending a process, update existing steps and connections rather than tearing down and rebuilding — and run the handle pass on every connection you add.
- Verify after building: `list_steps` with `include` for roles, tools, attributes, duration, frequency, and connections. A field missing from a response means you didn't request it, not that it's empty — include what you're checking.
