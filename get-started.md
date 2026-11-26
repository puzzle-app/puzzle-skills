# Set up Puzzle for an agent

You are an AI agent, and your user asked you to set up [Puzzle](https://puzzleapp.io) for them. Follow this page in order. It connects you to their Puzzle workspace, gives you the skills to work in it, and sets you up to record your work there as runs.

Puzzle is a map of how a business runs: processes, the team, the tools and the data, with a changelog of decisions and a record of the runs agents perform. You reach it through the Puzzle MCP server. The skills are the method for using it well.

## Ground rules

- Tell the user what you are about to install before you install it, and wait for their yes.
- The user signs in to Puzzle themselves, in their browser. Never ask for a password, an API key or a token.
- Setup writes nothing to the workspace. After setup, show what you plan to write and get approval first, as each skill describes.
- If a step fails, say which one and what the error was. Don't work around it.

## 1. Connect and install

Pick the section that matches what you are.

### Claude Code

Three plugins make up the full setup. The aim is that all three are in place when you finish, whatever the user already had.

| Plugin | What it gives |
|---|---|
| `puzzle` | The connection to Puzzle (the MCP server). |
| `puzzle-skills` | The skills. It comes with either of the other two. |
| `puzzle-runs` | Run logging: every session starts with the instruction to record mapped work as runs, and you are reminded once to close a run you left open. |

First see what is already there. Run these in the shell:

```bash
claude plugin marketplace add puzzle-app/puzzle-skills
```

```bash
claude plugin marketplace update puzzle-skills
```

```bash
claude plugin list
```

```bash
claude mcp list
```

The first command says the marketplace is already added if it is; that is fine. Then install only what is missing:

- **`puzzle`**: install it unless the plugin is already listed, or `claude mcp list` already shows a server at `https://app.puzzleapp.io/mcp`. A user who connected Puzzle another way keeps that connection; don't add a second one.
- **`puzzle-runs`**: install it unless it is already listed.
- **`puzzle-skills`**: no command needed. The other two bring it. If it was already installed, the update below brings it up to date.

```bash
claude plugin install puzzle@puzzle-skills --scope user
```

```bash
claude plugin install puzzle-runs@puzzle-skills --scope user
```

For each plugin that was already installed, update it, so the user is not left on an old version. Use the plugin's own name, and add `--scope project` or `--scope local` if `claude plugin list` shows it installed at that scope:

```bash
claude plugin update puzzle-skills@puzzle-skills
```

Tell the user that `puzzle-runs` turns run logging on for every Claude Code session on this machine, that it sends nothing itself (you make each logging call through their Puzzle connection), and that `claude plugin uninstall puzzle-runs@puzzle-skills` turns it off. If they want it for one project only, install it with `--scope project` from that project's folder instead.

A plugin loads when a session starts, so ask the user to start a new session. If you installed `puzzle`, they run `/mcp` in it, choose `plugin:puzzle:puzzle`, and sign in. Puzzle asks which workspace to connect.

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

In Claude Code, `puzzle-runs` repeats this instruction at the start of every session, so later sessions log without being asked. Everywhere else, this page is the only reminder: tell the user that in a new conversation they may need to ask you to log the work.

Runs is available on some workspaces only. If the `log_run_event` and `list_runs` tools are missing from your tool list, tell the user and carry on with the work; `log-runs` explains what that means.

## 5. Tell the user what you did

Finish with a short summary: what was installed and what was already there, which workspace is connected, whether run logging is on and how to turn it off, and what `start-here` suggests doing first.
