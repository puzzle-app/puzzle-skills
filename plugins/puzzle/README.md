# Puzzle plugin

Puzzle in one install for Claude Code: the Puzzle MCP connector and the sixteen [Puzzle skills](../../README.md).

## What it installs

- **The Puzzle MCP server** (`https://app.puzzleapp.io/mcp`), so your agent can read and write your workspace: the Workflow, Team, People and Tools canvases and the changelog.
- **The `puzzle-skills` plugin**, as a dependency. The skills are not copied; they come from the same marketplace and stay namespaced as `/puzzle-skills:<name>`.

## Install

```bash
claude plugin marketplace add puzzle-app/puzzle-skills
```

```bash
claude plugin install puzzle@puzzle-skills --scope user
```

Then start a session, run `/mcp`, pick `plugin:puzzle:puzzle` and sign in to Puzzle. Choose the workspace to connect when Puzzle asks. A free workspace is enough.

Start with `/puzzle-skills:start-here`.

## Already connected to Puzzle?

If Puzzle is already connected (a claude.ai connector, or your own MCP entry), install `puzzle-skills@puzzle-skills` on its own instead, so you don't end up with two connections to the same workspace.

## One workspace per connection

The connector signs in to one workspace. To work across several workspaces, add a separate MCP entry per workspace and use the skills-only plugin.
