# Puzzle skills

**Nine skills that make an MCP-connected agent competent in a [Puzzle](https://puzzleapp.io) workspace. Read the map, build a process, interview for one, map the team, map tools and data, log a decision, cost a process, find what to automate, audit what's there.**

The Puzzle MCP gives an agent the tools: list, create, update, link, across the four canvases and the changelog. It does not give the agent the method. Connect Claude to a workspace with nothing else and the first map it builds has steps with no executor, a fork with a branch that goes nowhere, a role with no hourly rate so the cost sidebar reads zero, and arrows entering steps from the wrong side. I know because I watched it happen, then wrote down every correction.

These skills are those corrections, split by what the map can do rather than by who is doing the work. They are the same whether you are one person mapping your own operation, an ops lead mapping a department, an IT lead mapping the systems behind every process, a consultant mapping a client, or someone building agents that need to know how the business runs.

They are plain `SKILL.md` files in the open Agent Skills format. Claude Code, Cowork, claude.ai and Claude Desktop read them as is. Any other agent that can read a markdown file and call the Puzzle MCP can use them too.

**[The nine skills](#the-nine-skills)** · [Install](#install) · [Where to start](#where-to-start-by-role) · [How they fit together](#how-they-fit-together) · [What they never do](#what-they-never-do)

## The nine skills

| Skill | What the agent can do once it has it | Writes? |
|---|---|---|
| [read-the-map](skills/read-the-map/SKILL.md) | Answer any question from the workspace: walk a process in order, who owns a step, what runs on a tool and what breaks if it changes, what data a step touches, what something costs, why a decision was made, what is outstanding, what is public. The foundation; every other skill loads it first. | No |
| [build-puzzle-process](skills/build-puzzle-process/SKILL.md) | Build a complete process in one shot: one intake round, one section, every step typed, owned, costed and noted, a grid sketch and a handle table for the connectors, a visual check, a changelog entry. | Yes |
| [interview-for-a-process](skills/interview-for-a-process/SKILL.md) | Prepare the questions for one conversation about one process, in run order, mapped to the fields a step needs. For a teammate, a client, or yourself. | No |
| [map-the-team](skills/map-the-team/SKILL.md) | Teams, roles with hourly rates and their basis, reporting lines, people in roles, tool access. Roles own steps; people hold roles. | Yes |
| [map-tools-and-data](skills/map-tools-and-data/SKILL.md) | The tech stack with costs and status, the records and fields each tool holds, the templates and reports inside tools, and the links from all of it to the steps that use it. | Yes |
| [log-a-decision](skills/log-a-decision/SKILL.md) | A changelog entry with the rationale, the trade-offs, the specs, the owner, the status, and links to the steps and tools it touches. | Yes |
| [cost-a-process](skills/cost-a-process/SKILL.md) | Labor and allocated tool cost per step, section and tab; the net, hours returned and payback against a future state. Every figure traces to the map; nothing is estimated. | No |
| [find-automation-opportunities](skills/find-automation-opportunities/SKILL.md) | Every step that could be automated, handed to an agent or AI-assisted, grouped and ranked, with prerequisites and phases. | No |
| [audit-the-map](skills/audit-the-map/SKILL.md) | Every gap between the map and a complete, current picture, scored and ranked, with the fixes proposed and applied one approved batch at a time. | After approval |

## Install

You need a Puzzle workspace connected to your agent through the Puzzle MCP. A free workspace is enough.

**Claude Code, as a plugin.** The repo is its own marketplace:

```bash
claude plugin marketplace add puzzle-app/puzzle-skills
```

```bash
claude plugin install puzzle-skills@puzzle-skills --scope user
```

Or inside a session: `/plugin marketplace add puzzle-app/puzzle-skills`, then `/plugin install puzzle-skills@puzzle-skills`. Skills arrive namespaced, so `/puzzle-skills:read-the-map` and friends. `claude plugin update puzzle-skills@puzzle-skills` pulls new versions.

**Claude Code, without the marketplace.** Clone the repo into your skills folder. Claude Code loads any folder there that carries a plugin manifest:

```bash
git clone https://github.com/puzzle-app/puzzle-skills.git ~/.claude/skills/puzzle-skills
```

**Claude.ai, Claude Desktop, Cowork.** Download the `.skill` files you want from the [latest release](https://github.com/puzzle-app/puzzle-skills/releases/latest) and upload each as a custom skill in your Claude settings. Each skill is its own file, so take the ones you need.

**Any other agent.** Point it at the `SKILL.md` for the job at hand. The files are markdown with a name and a description up front; nothing in them depends on a particular client.

## Where to start, by role

The skills don't change by role. The reading order does.

| You are | Start with | Then | When you need it |
|---|---|---|---|
| **A solo operator** mapping your own business | read-the-map, interview-for-a-process (on yourself) | build-puzzle-process, map-the-team (your hats are roles), map-tools-and-data | cost-a-process to see what your time goes to, find-automation-opportunities to get it back |
| **An ops lead** mapping a department | read-the-map, map-the-team | interview-for-a-process per teammate, build-puzzle-process per process, log-a-decision every time something changes | audit-the-map before a review, cost-a-process for the budget conversation |
| **An IT or transformation lead** | read-the-map (the tool impact question), map-tools-and-data | audit-the-map, log-a-decision for every system change | find-automation-opportunities for the roadmap, cost-a-process for the case |
| **A consultant** mapping a client | interview-for-a-process, build-puzzle-process on a Current State tab | map-the-team and map-tools-and-data as the interviews surface them, log-a-decision for every decision | find-automation-opportunities and cost-a-process for the proposal; build-puzzle-process again on a Future State tab |
| **An agent builder** | read-the-map | map-tools-and-data (the data your agent reads and writes), log-a-decision when an agent takes over a step | audit-the-map to keep the map your agent runs on close to reality |

## How they fit together

```text
interview-for-a-process     what to ask before mapping
        ↓
build-puzzle-process        the process, complete in one shot
   ↑        ↑
map-the-team   map-tools-and-data     the owners, rates, systems, records, assets the build links to
        ↓
log-a-decision              why it looks the way it does
        ↓
cost-a-process ← find-automation-opportunities     what it costs, what to change, what that returns
        ↓
audit-the-map               what drifted, fixed in approved batches

read-the-map                under all of it: the calls, the fields, the vocabulary, how to answer from the map
```

Three rules every write skill shares. The agent reads the workspace before it writes, so it extends what exists instead of duplicating it. It proposes the full change in chat and writes only after you approve. It records the change in the changelog with the reasoning, so the map keeps its history.

## What they never do

- Write to a workspace before you have approved the proposal.
- Invent a rate, a duration, a cost, a URL, an owner or a step to fill a gap. Gaps are reported and asked about.
- Put a person's name on a step. Roles own steps; people hold roles.
- Claim a tool can do something nobody has verified.
- Rebuild what exists. They edit in place and link to what is already there.
- Call a build done without a changelog entry.

## Make it yours

```text
skills/<name>/SKILL.md      one folder per skill; add your own alongside
.claude-plugin/             the plugin and marketplace manifests
scripts/package.sh          zips each skill into dist/<name>.skill for upload
```

Fork it, keep the nine, add the skills your operation needs: a client's naming conventions, a regulated approval path, a house style for notes. Skills that are specific to one business belong in that business's fork, not here.

## Related

- [build-puzzle-process](https://github.com/puzzle-app/build-puzzle-process) is the same build skill in its own repo, for people who only want that one.
- [grokbot-delivery-team](https://github.com/puzzle-app/grokbot-delivery-team) is a consultancy's delivery team as Grok Bot agents, with Puzzle as the shared memory; several of its skills are the consultant-specific ancestors of these.

## Versions

- **v1.0.1** (2026-10-22): build-puzzle-process description shortened to fit the 1,024-character limit on skill uploads, so the `.skill` file saves in claude.ai, Desktop and Cowork without editing.
- **v1.0** (2026-10-21): the nine skills, the plugin manifests, the packaged `.skill` files.

## License

[MIT](LICENSE). Built by [Brian Ragone](https://www.linkedin.com/in/bragone/), founder of [Puzzle](https://puzzleapp.io).
