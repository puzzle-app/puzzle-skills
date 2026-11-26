# Set up Puzzle for an agent

You are an AI agent, and your user asked you to set up [Puzzle](https://puzzleapp.io) for them. Follow this page in order. It connects you to their Puzzle workspace and gives you the skills to work in it.

Puzzle is a map of how a business runs: processes, the team, the tools and the data, with a changelog of decisions and a record of the runs agents perform. You reach it through the Puzzle MCP server. The skills are the method for using it well.

## Ground rules

- Tell the user what you are about to install before you install it, and wait for their yes.
- The user signs in to Puzzle themselves, in their browser. Never ask for a password, an API key or a token.
- Setup writes nothing to the workspace. After setup, show what you plan to write and get approval first, as each skill describes.
- If a step fails, say which one and what the error was. Don't work around it.

## 1. Connect and install

Pick the section that matches what you are.

### Claude Code

Run these two commands in the shell:

```bash
claude plugin marketplace add puzzle-app/puzzle-skills
```

```bash
claude plugin install puzzle@puzzle-skills --scope user
```

This installs the Puzzle MCP server and the Puzzle skills together. If the user already has Puzzle connected to Claude Code, install `puzzle-skills@puzzle-skills` instead, which is the skills without a second connection.

A plugin loads when a session starts, so ask the user to start a new session. In it, they run `/mcp`, choose `plugin:puzzle:puzzle`, and sign in. Puzzle asks which workspace to connect.

### Claude.ai, Claude Desktop or Cowork

You cannot install these yourself. Give the user these two steps:

1. Add Puzzle as a connector in their Claude settings, with the server URL `https://app.puzzleapp.io/mcp`, and sign in.
2. Download the `.skill` files from the [latest release](https://github.com/puzzle-app/puzzle-skills/releases/latest) and upload them as skills in their Claude settings.

### Any other agent

1. Add a remote MCP server (streamable HTTP) at `https://app.puzzleapp.io/mcp`. It uses OAuth; the user signs in when your client opens the browser.
2. The skills are markdown files. Read the one you need, when you need it, from `https://raw.githubusercontent.com/puzzle-app/puzzle-skills/main/skills/<name>/SKILL.md`. The names are listed in the [README](https://github.com/puzzle-app/puzzle-skills#the-sixteen-skills).

## 2. Check the connection

Call `list_tabs` with `canvas` set to `workflows`. A list of tabs, or an empty list for a new workspace, means you are connected. An authentication error means the sign-in did not finish; ask the user to sign in again.

## 3. Start in the right place

Load the `start-here` skill (`/puzzle-skills:start-here` in Claude Code) and follow it. It reads what the workspace already holds and proposes what to map next. Load `read-the-map` before answering any question from the workspace.

## 4. Record your work as runs

When you do real work that the workspace maps as a process, load `log-runs` and record it: one event per meaningful action, on the step it belongs to, and every run closed as success or failed. The step shows you working on the canvas, and the Runs page shows what happened.

Runs is available on some workspaces only. If the `log_run_event` and `list_runs` tools are missing from your tool list, tell the user and carry on with the work; `log-runs` explains what that means.

## 5. Tell the user what you did

Finish with a short summary: what was installed, which workspace is connected, and what `start-here` suggests doing first.
