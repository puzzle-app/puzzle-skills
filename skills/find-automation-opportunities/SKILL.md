---
name: find-automation-opportunities
description: Read a Puzzle workspace through the Puzzle MCP and find every step that could be automated, handed to an AI agent, or AI-assisted, grouped into opportunities, ranked, with the steps each touches, the prerequisites, the phase it lands in, and hours returned only where the costing inputs make the figure defensible. Load when the user asks "what could we automate", "where does AI fit", "which steps should an agent do", "automation roadmap", "AI opportunity roadmap", "what should we build next", or wants a future state drafted from the current state. Output is a ranked roadmap proposed in chat; building it is build-puzzle-process on a future state tab.
---

# Find automation opportunities

The question after any current state map: where does software or an agent take over, in what order, and what has to be true first. This skill answers from the map, so every opportunity points at steps that exist, and keeps the figures honest.

Load `read-the-map` first. Use `cost-a-process` for any dollar figure.

## Inputs

- The current state in the workspace: every section and step in scope with executor, role, tools, attributes, duration, frequency, notes.
- Pain points: in step notes, in changelog entries, in interview output, or from the user.
- Constraints the user has named: regulated steps, data that cannot leave a system, decisions a human must make, tools that are fixed.
- The changelog, for decisions already made and opportunities already logged.

## Read

1. `list_tabs` and `list_sections` for the scope, with `include: ["step_count", "notes"]`.
2. `list_steps` per section with `include: ["type", "executor", "status", "notes", "duration", "frequency", "roles.role_name", "tools.tool_id", "tools.tool_name"]`.
3. `list_attributes` with `include: ["steps.step_id", "steps.kind", "entity_name", "tool_name", "field_type"]` to see which steps move structured data between systems.
4. `list_tools` scope `workspace` with `include: ["status", "notes"]` for what is already in the stack, and which of it has an API or an automation connector.
5. `list_changelog_entries` with `query` on words like "automate", "agent", "integration", "Zapier", "Make", "n8n" to find what was already decided.

## Classify every Person step

One of four:

- **Automate.** Rule-based, structured inputs, in a system with an API or a connector on the user's automation platform. Copying a field from one record to another, sending a templated message on a status change, creating a record from a form. Executor becomes Automation.
- **AI agent.** Reads unstructured input (an email, a document, a transcript, a ticket) and produces a draft, a classification, an extraction or a recommendation a human reviews. Executor becomes AI Agent, usually followed by a Person review step.
- **Assist.** The human still does it; AI prepares the input or checks the output. Research before a call, a first draft, a summary of a thread.
- **Keep human.** Judgment, relationship, negotiation, compliance, anything the user's constraints say stays with a person.

Signals that a step is a candidate: a tool with an API, attributes linked as input from one system and output to another, a high frequency, a note that says "copy", "check", "re-enter", "chase", "remind", a pain point attached.

## Group into opportunities

One opportunity is one coherent change, not one step: a handoff automated end to end, an intake triaged by an agent, a report generated instead of compiled, a reminder sequence that stops someone chasing. List every step each opportunity touches by section, name and id. A step can appear in only one opportunity.

## Prerequisites

For each opportunity, name what must be true first: the system and whether it is in the stack; the data that must exist and be clean (the attributes the steps rely on); the integration or connector; the decision the user must make (a tool choice, a policy); the build that must come before it. An opportunity with an unmet prerequisite cannot land in the first phase.

## Rank

1. Steps touched, weighted by pain: a step with a pain point in a note or a changelog entry counts double.
2. Prerequisites already met.
3. Hours per month returned, where duration and frequency exist on the steps touched (duration ÷ 60 × frequency, summed). Where either is missing on a step, the figure is "not defensible: missing duration or frequency" and the gap is reported, not estimated.
4. Risk: what breaks if the automation misfires, and how visible it is. A wrong email to a customer outranks a wrong internal tag.

## Phases

- **Now**: prerequisites met, in the current stack, low risk.
- **Next**: one prerequisite to clear (a connector, a data cleanup, a decision).
- **Later**: a new system, a policy decision, or a dependency on another build.

## Output format

```
# Automation opportunities: <scope>
From the current state map on <date>. <n> sections, <n> Person steps reviewed.

## Summary
- <n> opportunities: <n> automate, <n> AI agent, <n> assist
- Now: <n>. Next: <n>. Later: <n>.
- Hours per month returned where defensible: <n> (on <n> of <n> steps with costing inputs)

## Ranked opportunities
### 1. <Name>: <Automate | AI agent | Assist>
Steps touched: <section: step (id), ...>
Pain resolved: <from notes, changelog, interview, or "none recorded">
What changes: <two lines: who or what does it after, and what the human still does>
Prerequisites: <system · data · integration · decision · build>
Phase: <Now | Next | Later>
Hours per month returned: <n> | not defensible: <reason>
Risk: <one line>

### 2. ...

## Kept human, and why
- <section: step>: <reason>

## Decisions needed first
- ...

## Steps missing inputs that would make the figures defensible
- ...
```

## From roadmap to map

When the user picks opportunities to pursue:

1. Record the roadmap as a changelog entry with `log-a-decision` (status planned), linked to the steps touched and the tools involved.
2. Build the future state with `build-puzzle-process` on a Future State tab, copying the current section and changing the executors, tools and steps the opportunity describes. Never edit the current state to show a future that isn't running.
3. Annotate every Automation and AI Agent step in the future state with the pain point it resolves, in the note.
4. Cost the before and after with `cost-a-process` and put the scenario on the entry.

## Rules

- Every opportunity names steps that exist in the workspace. No opportunity without a step.
- Never claim a tool can do something you haven't verified on the vendor's documentation or that the user has confirmed. Say "if <tool> supports X" when you haven't.
- Regulated or constrained steps are never proposed for automation without the user's explicit say-so, recorded in the changelog.
- An AI agent step almost always needs a human review step after it. Include it, and cost it.
- The roadmap is a proposal. The user decides what goes in the future state.
